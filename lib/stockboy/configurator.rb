require 'stockboy/providers'
require 'stockboy/readers'
require 'stockboy/filters'
require 'stockboy/attribute_map'
require 'stockboy/provider_repeater'

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
    def initialize(dsl='', file=__FILE__, env_variables={}, &block)
      @config = {}
      @config[:triggers] = Hash.new { |hash, key| hash[key] = [] }
      @config[:filters] = {}

      env.merge! env_variables

      if block_given?
        instance_eval(&block)
      else
        instance_eval(dsl, file)
      end
    end

    # Configure the provider for fetching data
    #
    # The optional block is evaluated in the provider's own DSL context.
    #
    # @param [Symbol, Class, Provider] key
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
    def provider(key, opts={}, &block)
      @config[:provider] = Providers.build(key, opts, block)
    end
    alias_method :connection, :provider

    # Configure repeating the provider for fetching multiple parts
    #
    # If the provider needs to give us all the data as a series of requests,
    # for example multiple HTTP pages or FTP files, the repeat block can be
    # used to define the iteration for fetching each item.
    #
    # The `<<` interface used here is defined by Ruby's Enumerator.new block
    # syntax. For each page that needs to be fetched, the provider options need
    # to be altered and pushed on to the output. Control will be yielded to the
    # reader at each iteration.
    #
    # @example
    #   repeat do |output, provider|
    #     loop do
    #       output << provider
    #       break if provider.data.split("\n").size < 100
    #       provider.query_params["page"] += 1
    #     end
    #   end
    #
    # @example
    #   repeat do |output, provider|
    #     1.upto 10 do |i|
    #       provider.file_name = "example-#{i}.log"
    #       output << provider
    #     end
    #   end
    #
    def repeat(&block)
      unless block_given? && block.arity == 2
        raise ArgumentError, "repeat block must accept |output, provider| arguments"
      end

      @config[:repeat] = block
    end

    # Configure the reader for parsing data
    #
    # @param [Symbol, Class, Reader] key
    #   The registered symbol name for the reader, or actual reader instance
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
    def reader(key, opts={}, &block)
      @config[:reader] = Readers.build(key, opts, block)
    end
    alias_method :format, :reader

    # Configure the attribute map for data records
    #
    # This will replace any existing attributes with a new set.
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

    # Add individual attribute mapping rules
    #
    # @param [Symbol] key Name of the output attribute
    # @param [Hash] opts
    # @option opts [String] from Name of input field from reader
    # @option opts [Array,Proc,Translator] as One or more translators
    #
    #
    def attribute(key, opts={})
      @config[:attributes] ||= AttributeMap.new
      @config[:attributes].insert(key, opts)
    end

    # Add a filter to the processing filter chain
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
      filter = Filters.build(callable, args, block) || block
      filter or raise ArgumentError, "Missing filter arguments for #{key}"
      @config[:filters][key] = filter
    end

    def env
      @config[:env] ||= Hash.new do |hash, key|
        raise DSLEnvVariableUndefined, "#{key} not defined"
      end
    end

    # Register a trigger to notify the job of external events
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
      Job.new(config_for_job)
    end

    private

    def config_for_job
      config.dup.tap { |config| wrap_provider(config) }
    end

    def wrap_provider(config)
      return unless (repeat = config.delete(:repeat))
      config[:provider] = ProviderRepeater.new(config[:provider], &repeat)
    end

  end
end
