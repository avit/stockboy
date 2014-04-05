require 'stockboy/configuration'
require 'stockboy/exceptions'
require 'stockboy/configurator'
require 'stockboy/template_file'
require 'stockboy/filter_chain'
require 'stockboy/candidate_record'

module Stockboy

  # This class wraps up the main interface for the process of fetching,
  # parsing and sorting data. When used with a predefined template file, you
  # can pass the name of the template to define it. This is the common way
  # to use Stockboy:
  #
  #   job = Stockboy::Job.define('my_template')
  #   if job.process
  #     job.records[:update].each do |r|
  #       # ...
  #     end
  #     job.records[:cancel].each do |r|
  #       # ...
  #     end
  #   end
  #
  class Job

    # Defines the data source for receiving data
    #
    # @return [Provider]
    #
    attr_accessor :provider

    # Defines the format for parsing received data
    #
    # @return [Reader]
    #
    attr_accessor :reader

    # Configures the mapping & translation of raw data fields
    #
    # @return [AttributeMap]
    #
    attr_reader :attributes

    # List of filters for sorting processed records
    #
    # @return [FilterChain]
    #
    # Filters are applied in order, first match will capture the record.
    # Records that don't match any
    #
    attr_reader :filters

    attr_reader :triggers

    # Lists of records grouped by filter key
    #
    # @return [Hash{Symbol=>Array}]
    #
    attr_reader :records

    # List of records not matched by any filter
    #
    # @return [Array<CandidateRecord>]
    #
    attr_reader :unfiltered_records

    # List of all records, filtered or not
    #
    # @return [Array<CandidateRecord>]
    #
    attr_reader :all_records

    # Initialize a new job
    #
    # @param [Hash] params
    # @option params [Provider]           :provider
    # @option params [Reader]             :reader
    # @option params [AttributeMap]       :attributes
    # @option params [Array,FilterChain]  :filters
    # @yield instance for further configuration or processing
    #
    def initialize(params={}, &block)
      @provider   = params[:provider]
      @reader     = params[:reader]
      @attributes = params[:attributes] || AttributeMap.new
      @filters    = FilterChain.new params[:filters]
      @triggers   = Hash.new { |h,k| h[k] = [] }
      @triggers.replace params[:triggers] if params[:triggers]
      yield self if block_given?
      reset
    end

    # Instantiate a job configured by DSL template file
    #
    # @param template_name [String] File basename from template load path
    # @yield instance for further configuration or processing
    # @see Configuration#template_load_paths
    #
    def self.define(template_name)
      return nil unless template = TemplateFile.read(template_name)
      job = Configurator.new(template, TemplateFile.find(template_name)).to_job
      yield job if block_given?
      job
    end

    # Fetch data and process it into groups of filtered records
    #
    # @return [Boolean] Success or failure
    #
    def process
      with_query_caching do
        load_records
        yield @records if block_given?
      end
      provider.errors.empty?
    end

    def data(&block)
      provider.data(&block)
    end

    def data?(reduction=:all?)
      provider.data?(reduction)
    end

    # Count of all processed records
    #
    # @!attribute [r] total_records
    # @return [Fixnum]
    #
    def total_records
      @all_records.size
    end

    # Counts of processed records grouped by filter key
    #
    # @return [Hash{Symbol=>Fixnum}]
    #
    def record_counts
      @records.reduce(Hash.new) { |a, (k,v)| a[k] = v.size; a }
    end

    def triggers=(new_triggers)
      @triggers.replace new_triggers
    end

    def trigger(key, *args)
      return nil unless triggers.key?(key)
      triggers[key].each do |c|
        c.call(self, *args)
      end
    end

    def method_missing(name, *args)
      if triggers.key?(name)
        trigger(name, *args)
      else
        super
      end
    end

    # Replace existing filters
    #
    # @param new_filters [Array]
    # @return [Stockboy::FilterChain]
    #
    def filters=(new_filters)
      @filters.replace new_filters
      reset
      @filters
    end

    # Replace existing attribute map
    #
    # @param new_attributes [Stockboy::AttributeMap]
    # @return [Stockboy::AttributeMap]
    #
    def attributes=(new_attributes)
      @attributes = new_attributes
      reset
      @attributes
    end

    # Has the job been processed successfully?
    #
    # @return [Boolean]
    #
    def processed?
      !!@processed
    end

    # Overview of the job configuration; tries to be less noisy by hiding
    # sub-element details.
    #
    # @return [String]
    #
    def inspect
      prov = "provider=#{(Stockboy::Providers.all.key(provider.class) || provider.class)}"
      read = "reader=#{(Stockboy::Readers.all.key(reader.class) || reader.class)}"
      attr = "attributes=#{attributes.map(&:to)}"
      filt = "filters=#{filters.keys}"
      cnts = "record_counts=#{record_counts}"
      "#<#{self.class}:#{self.object_id} #{[prov, read, attr, filt, cnts].join(', ')}>"
    end

    private

    def reset
      @records = filters.reset
      @all_records = []
      @unfiltered_records = []
      @processed = false
      true
    end

    def load_records
      reset
      load_all_records
      return unless provider.data?
      partition_all_records
      @processed = true
    end

    def load_all_records
      each_reader_row do |row|
        @all_records << CandidateRecord.new(row, @attributes)
      end
    end

    def partition_all_records
      @all_records.each do |record|
        record_partition(record) << record
      end
    end

    def each_reader_row
      return to_enum(__method__) unless block_given?
      with_provider_data do |data|
        reader.parse(data).each do |row|
          yield row
        end
      end
    end

    # Allows for a data method that either yields or returns giving preference
    # to the yield. It will ignore the data return value if it has yielded.
    #
    def with_provider_data
      return to_enum(__method__) unless block_given?
      yielded = nil
      provider.data do |data|
        if data
          yielded = true
          yield data
        end
      end
      return if yielded
      yield(provider.data) if provider.data
    end

    def record_partition(record)
      if key = record.partition(filters)
        @records[key]
      else
        @unfiltered_records
      end
    end

    def with_query_caching(&block)
      if defined? ActiveRecord
        ActiveRecord::Base.cache(&block)
      else
        yield
      end
    end

  end
end
