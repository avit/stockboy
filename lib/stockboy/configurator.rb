require 'stockboy/job'
require 'stockboy/providers'
require 'stockboy/readers'
require 'stockboy/filters'
require 'stockboy/attribute_map'

module Stockboy

  # Context for evaluating DSL templates and capturing job options for
  # initializing a job.
  #
  # Wraps up the DSL methods called in job templates and handles the construction
  # of the job's +provider+, +reader+, +attributes+, and +filters+.
  #
  class Configurator

    # Captured job configuration options
    #
    # @return [Hash]
    #
    attr_reader :config

    # Evaluate DSL and capture configuration for building a job
    #
    # @overload new(dsl, file=__FILE__)
    #   Evaluate DSL from a string
    #   @param [String] dsl   job template language for evaluation
    #   @param [String] file  path to original file for reporting errors
    # @overload new(&block)
    #   Evaluate DSL in a block
    #
    def initialize(dsl='', file=__FILE__, &block)
      @config = {}
      @config[:triggers] = Hash.new { |hash, key| hash[key] = [] }
      @config[:filters] = {}
      if block_given?
        instance_eval(&block)
      else
        instance_eval(dsl, file)
      end
    end

    # DSL method for configuring the provider
    #
    # The optional block is evaluated in the provider's own DSL context.
    #
    # @param [Symbol, Class, Provider] provider_class
    #   The registered symbol name for the provider, or actual provider
    # @param [Hash] opts
    #   Provider-specific options passed to the provider initializer
    #
    # @example
    #   provider :file, file_dir: "/downloads/@client" do
    #     file_name "example.csv"
    #   end
    #
    # @return [Provider]
    #
    def provider(provider_class, opts={}, &block)
      raise ArgumentError unless provider_class

      @config[:provider] = case provider_class
      when Symbol
        Providers.find(provider_class).new(opts, &block)
      when Class
        provider_class.new(opts, &block)
      else
        provider_class
      end
    end
    alias_method :connection, :provider

    # DSL method for configuring the reader
    #
    # @param [Symbol, Class, Reader] reader_class
    #   The registered symbol name for the reader, or actual reader
    # @param [Hash] opts
    #   Provider-specific options passed to the provider initializer
    #
    # @example
    #   reader :csv do
    #     col_sep "|"
    #   end
    #
    # @return [Reader]
    #
    def reader(reader_class, opts={}, &block)
      raise ArgumentError unless reader_class

      @config[:reader] = case reader_class
      when Symbol
        Readers.find(reader_class).new(opts, &block)
      when Class
        reader_class.new(opts, &block)
      else
        reader_class
      end
    end
    alias_method :format, :reader

    # DSL method for configuring the attribute map in a block
    #
    # @example
    #   attributes do
    #     first_name as: ->(raw){ raw["FullName"].split(" ").first }
    #     email      from: "RawEmail", as: [:string]
    #     check_in   from: "RawCheckIn", as: [:date]
    #   end
    #
    def attributes(&block)
      raise ArgumentError unless block_given?

      @config[:attributes] = AttributeMap.new(&block)
    end

    # DSL method to add a filter to the filter chain
    #
    # * Must be called with either a callable argument (proc) or a block.
    # * Must be called in the order that filters should be applied.
    #
    # @example
    #   filter :missing_email do |raw, out|
    #     raw["RawEmail"].empty?
    #   end
    #   filter :past_due do |raw, out|
    #     out.check_in < Date.today
    #   end
    #   filter :under_age, :check_id
    #   filter :update, proc{ true } # capture all remaining items
    #
    def filter(key, callable=nil, *args, &block)
      raise ArgumentError unless key
      if callable.is_a?(Symbol)
        callable = Filters.find(callable)
        callable = callable.new(*args) if callable.is_a? Class
      end
      raise ArgumentError unless callable.respond_to?(:call) ^ block_given?

      @config[:filters][key] = block || callable
    end

    # DSL method to register a trigger to notify the job of an event
    #
    # Useful for adding generic control over the job's resources from your app.
    # For example, if you need to record stats or clean up data after your
    # application has successfully processed the records, these actions can be
    # defined within the context of each job template.
    #
    # @param [Symbol] key Name of the trigger
    # @yieldparam [Stockboy::Job]
    # @yieldparam [Array] Arguments passed to the action when called
    #
    # @example
    #   trigger :cleanup do |job, *args|
    #     job.provider.delete_data
    #   end
    #
    #   # elsewhere:
    #   if MyProjects.find(123).import_records(job.records[:valid])
    #     job.cleanup
    #   end
    #
    def on(key, &block)
      raise(ArgumentError, "no block given") unless block_given?
      @config[:triggers][key] << block
    end

    # Initialize a new job with the captured options
    #
    # @return [Job]
    #
    def to_job
      Job.new(@config)
    end

  end
end
