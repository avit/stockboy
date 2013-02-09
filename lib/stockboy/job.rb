require 'stockboy/configuration'
require 'stockboy/exceptions'
require 'stockboy/configurator'
require 'stockboy/template_file'

module Stockboy
  class Job

    attr_accessor :provider
    attr_accessor :reader
    attr_reader :attributes
    attr_reader :filters

    attr_reader :records
    attr_reader :unfiltered_records
    attr_reader :all_records

    def initialize(params={}, &block)
      @provider   = params[:provider]
      @reader     = params[:reader]
      @attributes = params[:attributes]
      @filters    = params[:filters] || Hash.new
      yield self if block_given?
      reset
    end

    ## Instantiate a job configured by DSL template file
    #
    def self.define(template_name)
      return nil unless template = TemplateFile.read(template_name)
      job = Configurator.new(template, TemplateFile.find(template_name)).to_job
      yield job if block_given?
      job
    end

    def process
      reset
      with_query_caching do
        load_records
        yield @records if block_given?
      end
      provider.errors.empty?
    end

    def total_records
      @all_records.size
    end

    def record_counts
      @records.reduce(Hash.new) { |a, (k,v)| a[k] = v.size; a }
    end

    def filters=(new_filters)
      @filters = new_filters
      reset
      @filters
    end

    def attributes=(new_attributes)
      @attributes = new_attributes
      reset
      @attributes
    end

    private

    def reset
      @records = {}
      @all_records = []
      @unfiltered_records = []
      @filters.keys.each { |k| @records[k] = [] }
      true
    end

    def load_records
      return unless provider.data

      @all_records = reader.parse(provider.data).map do |row|
        CandidateRecord.new(row, @attributes)
      end

      @all_records.each do |record|
        record_partition(record) << record
      end
    end

    def record_partition(record)
      if key = record.partition(@filters)
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
