require 'stockboy/provider'

module Stockboy::Providers
  class File < Stockboy::Provider

    OPTIONS = [:file_name,
               :file_dir,
               :file_newer,
               :file_smaller,
               :file_larger,
               :pick]
    attr_accessor *OPTIONS
    alias :since :file_newer
    alias :since= :file_newer=

    class DSL
      include Stockboy::DSL
      dsl_attrs *OPTIONS
      alias :since :file_newer
      alias :since= :file_newer=
    end

    def initialize(opts={}, &block)
      super(opts, &block)
      @file_dir     = opts[:file_dir]
      @file_name    = opts[:file_name]
      @file_newer   = opts[:file_newer]
      @file_smaller = opts[:file_smaller]
      @file_larger  = opts[:file_larger]
      @pick         = opts[:pick] || :last
      DSL.new(self).instance_eval(&block) if block_given?
    end

    private

    def validate
      errors.add_on_blank [:file_dir, :file_name]
      errors.empty?
    end

    def fetch_data
      data_file = find_matching_file
      validate_file(data_file)
      @data = data_file.read if valid?
    end

    def find_matching_file
      case file_name
      when Regexp
        files = Dir.entries(file_dir)
                   .select { |i| i =~ file_name }
                   .map { |i| ::File.join(file_dir, i) }
      when String
        files = Dir[::File.join(file_dir, file_name)]
      end
      ::File.new(pick_file_from(files), 'r')
    end

    def pick_file_from(list)
      case @pick
      when Symbol
        list.public_send @pick
      when Proc
        list.detect &@pick
      end
    end

    def validate_file(data_file)
      validate_file_newer(data_file)
      validate_file_smaller(data_file)
      validate_file_larger(data_file)
    end

    def validate_file_newer(file)
      if file_newer && file.mtime < file_newer
        errors.add :response, "No new files since #{file_newer}"
      end
    end

    def validate_file_smaller(file)
      if file_smaller && file.size > file_smaller
        errors.add :response, "File size larger than #{file_smaller}"
      end
    end

    def validate_file_larger(file)
      if file_larger && file.size < file_larger
        errors.add :response, "File size smaller than #{file_larger}"
      end
    end
  end
end
