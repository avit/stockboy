require 'stockboy/provider'

module Stockboy::Providers

  # Get data from a local file
  #
  # Allows for selecting the appropriate file to be read from the given
  # directory by glob pattern or regex pattern. By default the +:last+ file in
  # the list is used, but can be controlled by sorting and reducing with the
  # {#pick} option.
  #
  # == Job template DSL
  #
  #   provider :file do
  #     file_dir '/data'
  #     file_name /report-[0-9]+\.csv/
  #     pick ->(list) { list[-2] }
  #   end
  #
  class File < Stockboy::Provider

    # @!group Options

    # @macro provider.file_options
    dsl_attr :file_name
    dsl_attr :file_dir
    dsl_attr :file_newer, alias: :since

    # @macro provider.file_size_options
    dsl_attr :file_smaller
    dsl_attr :file_larger

    # @macro provider.pick_option
    dsl_attr :pick

    # @!endgroup

    # Initialize a File provider
    #
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

    def delete_data
      raise Stockboy::OutOfSequence, "must confirm #matching_file or calling #data" unless picked_matching_file?

      logger.info "Deleting file #{file_dir}/#{matching_file}"
      ::File.delete matching_file
    end

    def matching_file
      @matching_file ||= pick_from(file_list.sort)
    end

    def clear
      super
      @matching_file = nil
      @data_size = nil
      @data_time = nil
    end

    private

    def fetch_data
      errors << "file #{file_name} not found" unless matching_file
      data_file = ::File.new(matching_file, 'r') if matching_file
      validate_file(data_file)
      @data = data_file.read if valid?
    end

    def validate
      errors << "file_dir must be specified" if file_dir.blank?
      errors << "file_name must be specified" if file_name.blank?
      errors.empty?
    end

    def picked_matching_file?
      !!@matching_file
    end

    def file_list
      case file_name
      when Regexp
        Dir.entries(file_dir)
           .select { |i| i =~ file_name }
           .map    { |i| full_path(i) }
      when String
        Dir[full_path(file_name)]
      end
    end

    def full_path(file_name)
      ::File.join(file_dir, file_name)
    end

    def validate_file(data_file)
      return errors << "no matching files" unless data_file
      validate_file_newer(data_file)
      validate_file_smaller(data_file)
      validate_file_larger(data_file)
    end

    def validate_file_newer(data_file)
      read_data_time(data_file)
      if file_newer && data_time < file_newer
        errors << "no new files since #{file_newer}"
      end
    end

    def validate_file_smaller(data_file)
      read_data_size(data_file)
      if file_smaller && data_size > file_smaller
        errors << "file size larger than #{file_smaller}"
      end
    end

    def validate_file_larger(data_file)
      read_data_size(data_file)
      if file_larger && data_size < file_larger
        errors << "file size smaller than #{file_larger}"
      end
    end

    def read_data_size(file)
      @data_size ||= file.size
    end

    def read_data_time(file)
      @data_time ||= file.mtime
    end

  end
end
