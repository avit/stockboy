require 'stockboy/configuration'
require 'stockboy/exceptions'
require 'stockboy/configurator'
require 'stockboy/template_file'

module Stockboy
  class Job

    attr_accessor :provider
    attr_accessor :reader
    attr_accessor :attributes
    attr_accessor :filters
    attr_accessor :workflow

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
      Configurator.new(template, TemplateFile.find(template_name)).to_job
    end

    def process
      reset
      load_records
      yield @records if block_given?
      provider.errors.empty?
    end

    def total_records
      @all_records.count
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

  end
end
