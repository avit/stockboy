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
      return @matching_file if @matching_file
      files = case file_name
      when Regexp
        Dir.entries(file_dir)
            .select { |i| i =~ file_name }
            .map { |i| ::File.join(file_dir, i) }
      when String
        Dir[::File.join(file_dir, file_name)]
      end
      @matching_file = pick_from(files) if files.any?
    end

    def clear
      super
      @matching_file = nil
      @data_size = nil
      @data_time = nil
    end

    private

    def fetch_data
      errors.add(:base, "File #{file_name} not found") unless matching_file
      data_file = ::File.new(matching_file, 'r') if matching_file
      validate_file(data_file)
      if valid?
        logger.info "Getting file #{file_dir}/#{matching_file}"
        @data = data_file.read
        logger.info "Got file #{file_dir}/#{matching_file} (#{@data_size} bytes)"
      end
    end

    def validate
      errors.add_on_blank [:file_dir, :file_name]
      errors.empty?
    end

    def picked_matching_file?
      !!@matching_file
    end

    def validate_file(data_file)
      return errors.add :response, "No matching files" unless data_file
      validate_file_newer(data_file)
      validate_file_smaller(data_file)
      validate_file_larger(data_file)
    end

    def validate_file_newer(data_file)
      @data_time ||= data_file.mtime
      if file_newer && @data_time < file_newer
        errors.add :response, "No new files since #{file_newer}"
      end
    end

    def validate_file_smaller(data_file)
      @data_size ||= data_file.size
      if file_smaller && @data_size > file_smaller
        errors.add :response, "File size larger than #{file_smaller}"
      end
    end

    def validate_file_larger(data_file)
      @data_size ||= data_file.size
      if file_larger && @data_size < file_larger
        errors.add :response, "File size smaller than #{file_larger}"
      end
    end
  end
end
