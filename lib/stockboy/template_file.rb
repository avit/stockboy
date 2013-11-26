require 'stockboy/configuration'

module Stockboy

  # Find and read template files from the configured load paths
  #
  module TemplateFile

    # Read template file contents for defining a new job
    #
    # @param [String] template_name
    #   The file basename of a predefined template
    # @return [String] Job template DSL or nil if nothing is found
    #
    def self.read(template_name)
      return template_name.read if template_name.is_a? File
      return unless path = find(template_name)

      File.read(path)
    end

    # Find a named DSL template from configuration.template_load_paths
    #
    # @param [String] filename Template basename to be searched from load paths
    # @return [String] The full path to the first matched filename if found
    #
    def self.find(filename)
      sources = template_file_paths(filename)
      Dir.glob(sources).first
    end

    # Potential locations for finding a template file
    #
    # @param [String] filename Template basename
    # @return [Array] filename on each possible load path
    #
    def self.template_file_paths(filename)
      filename = "#{filename}.rb" unless filename =~ /\.rb$/
      load_paths = Array(Stockboy.configuration.template_load_paths)
      load_paths.map { |d| File.join(d, filename) }
    end

  end
end
