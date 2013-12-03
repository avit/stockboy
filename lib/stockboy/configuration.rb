require 'logger'

module Stockboy

  # Global Stockboy configuration options
  #
  class Configuration

    # Directories where Stockboy job template files can be found.
    #
    # Needs to be configured with your own paths if running standalone.
    # When running with Rails, includes +config/stockboy_jobs+ by default.
    #
    # @return [Array<String>]
    #
    attr_accessor :template_load_paths

    # Path for storing tempfiles during processing
    #
    # @return [String]
    #
    attr_accessor :tmp_dir

    # Default logger
    #
    # @return [Logger]
    #
    attr_accessor :logger

    # Initialize a set of global configuration options
    #
    # @yield self for configuration
    #
    def initialize
      @template_load_paths = []
      @logger = Logger.new(STDOUT)
      @tmp_dir = Dir.tmpdir
      yield self if block_given?
    end
  end

  class << self

    # Stockboy configuration block
    #
    # @example
    #   Stockboy.configure do |config|
    #     config.template_load_paths << "config/my_templates"
    #   end
    #
    # @scope class
    # @yield self for configuration
    # @return [Configuration]
    #
    def configure
      @configuration ||= Configuration.new
      yield @configuration if block_given?
      @configuration
    end
    alias_method :configuration, :configure

  end

end
