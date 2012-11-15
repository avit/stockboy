module Stockboy
  class Configuration
    attr_accessor :template_load_paths

    def initialize
      @template_load_paths = []
      yield self if block_given?
    end
  end

  class << self
    def configure
      @configuration ||= Configuration.new
      yield @configuration if block_given?
      @configuration
    end
    alias_method :configuration, :configure
  end
end
