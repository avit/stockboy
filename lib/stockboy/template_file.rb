require 'stockboy/configuration'

module Stockboy
  module TemplateFile

    def self.read(template_name)
      return template_name.read if template_name.is_a? File
      return unless path = find(template_name)

      File.read(path)
    end

    ## Find a named DSL template from configuration.template_load_paths
    def self.find(filename)
      sources = template_file_paths(filename)
      Dir.glob(sources).first
    end

    def self.template_file_paths(filename)
      filename = "#{filename}.rb" unless filename =~ /\.rb$/
      load_paths = Array(Stockboy.configuration.template_load_paths)
      load_paths.map { |d| File.join(d, filename) }
    end

  end
end
