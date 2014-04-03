require 'logger'
require 'stockboy/dsl'
require 'stockboy/exceptions'

module Stockboy

  # Provider objects handle the connection and capture of data from remote
  # sources. This is an abstract superclass to help implement different
  # providers.
  #
  # == Interface
  #
  # A provider object must implement the following (private) methods:
  #
  # [validate]
  #   Verify the parameters required for the data source are set to
  #   ensure a connection can be established.
  # [fetch_data]
  #   Populate the object's +@data+ with raw content from source. This will
  #   usually be a raw string, and should not be parsed at this stage.
  #   Depending on the implementation, this may involve any of:
  #   * Establishing a connection
  #   * Navigating to a directory
  #   * Listing available files matching the configuration
  #   * Picking the appropriate file
  #   * And finally, reading/downloading data
  #   This should also capture the timestamp of the data resource into
  #   +@data_time+. This should be the actual created or updated time of the
  #   data file from the source.
  #
  # @abstract
  #
  class Provider
    extend Stockboy::DSL

    # @return [Logger]
    #
    attr_accessor :logger

    # @return [Array]
    #
    attr_reader :errors

    # Size of the received data
    #
    # @return [Time]
    #
    attr_reader :data_size

    # Timestamp of the received data
    #
    # @return [Time]
    #
    attr_reader :data_time

    # @return [String]
    #
    def inspect
      "#<#{self.class}:#{self.object_id} "\
      "data_size=#{@data_size.inspect} "\
      "errors=[#{errors.join(", ")}]>"
    end

    # Must be called by subclasses via +super+ to set up dependencies
    #
    # @param [Hash] opts
    # @yield DSL context for configuration
    #
    def initialize(opts={}, &block)
      @logger = opts.delete(:logger) || Stockboy.configuration.logger
      clear
    end

    # Raw input data from the source
    #
    # @!attribute [r] data
    #
    def data
      fetch_data if @data.nil? && validate_config?
      yield @data if block_given?
      @data
    end

    def data?
      @data_size && @data_size > 0
    end

    # Reset received data
    #
    # @return [Boolean] Always true
    #
    def clear
      @data = nil
      @data_time = nil
      @data_size = nil
      @errors = []
      true
    end
    alias_method :reset, :clear

    # Reload provided data
    #
    # @return [String] Raw data
    #
    def reload
      clear
      fetch_data if validate_config?
      @data
    end

    # Does the provider have what it needs for fetching data?
    #
    # @return [Boolean]
    #
    def valid?
      validate
    end

    private

    # Subclass should assign +@data+ with raw input, usually a string
    #
    # @abstract
    #
    def fetch_data
      raise NoMethodError, "#{self.class}#fetch_data needs implementation"
    end

    # Use errors << "'option' is required"
    # for validating required provider parameters before attempting
    # to make connections and retrieve data.
    #
    # @abstract
    #
    def validate
      raise NoMethodError, "#{self.class}#validate needs implementation"
    end

    def validate_config?
      unless validation = valid?
        logger.error do
          "Invalid #{self.class} provider configuration: #{errors.join(', ')}"
        end
      end
      validation
    end

    # When picking files from a list you can supply +:first+ or +:last+ to the
    # provider's +pick+ option, or else a block that can reduce to a single
    # value, like:
    #
    #     proc do |best_match, current_match|
    #       current_match.better_than?(best_match) ?
    #           current_match : best_match
    #     end
    #
    def pick_from(list)
      case @pick
      when Symbol
        list.public_send @pick
      when Proc
        list.reduce &@pick
      end
    end

  end

  # @!macro [new] provider.pick_validation
  #   This validation option is applied after a matching file is picked.

  # @!macro [new] provider.pick_option
  #   @group Options
  #
  #   @!attribute [rw] pick
  #     Method for choosing which file to process from potential matches.
  #       @example
  #         pick :last
  #         pick :first
  #         pick ->(list) {
  #           list.max_by { |name| Time.strptime(name[/\d+/], "%m%d%Y").to_i }
  #         }

  # @!macro [new] provider.file_options
  #   @group Options
  #
  #   @!attribute [rw] file_name
  #     A string (glob) or regular expression matching files. E.g. one of:
  #     @return [String, Regexp]
  #     @example
  #       file_name "export-latest.csv"
  #       file_name "export-*.csv"
  #       file_name /export-\d{4}-\d{2}-\d{2}.csv/
  #
  #   @!attribute [rw] file_dir
  #     Path where data files can be found. This should be an absolute path.
  #     @return [String]
  #     @example
  #       file_dir "/data"
  #
  #   @!attribute [rw] file_newer
  #     Validates that the file to be processed is recent enough. To guard
  #     against processing an old file (even if it's the latest one), this should
  #     be set to the frequency you expect to receive new files for periodic
  #     processing.
  #     @macro provider.pick_validation
  #     @return [Time, Date]
  #     @example
  #       since Date.today
  #

  # @!macro [new] provider.file_size_options
  #   @group Options
  #
  #   @!attribute [rw] file_smaller
  #     Validates the maximum data size for the matched file, in bytes
  #     @return [Fixnum]
  #     @macro provider.pick_validation
  #     @example
  #       file_smaller 1024^3
  #
  #   @!attribute [rw] file_larger
  #     Validates the minimum file size for the matched file, in bytes. This can # help guard against processing zero-byte or truncated files.
  #     @return [Fixnum]
  #     @macro provider.pick_validation
  #     @example
  #       file_larger 1024

end
