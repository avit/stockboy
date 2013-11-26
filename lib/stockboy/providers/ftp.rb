require 'stockboy/provider'
require 'net/ftp'

module Stockboy::Providers

  # Get data from a remote FTP server
  #
  # Allows for selecting the appropriate file to be read from the given
  # directory by glob pattern or regex pattern (glob string is more efficient
  # for listing files from FTP). By default the +:last+ file in the list is
  # used, but can be controlled by sorting and reducing with the {#pick}
  # option.
  #
  # == Job template DSL
  #
  #   provider :ftp do
  #     host      'ftp.example.com'
  #     username  'example'
  #     password  '424242'
  #     file_dir  'data/daily'
  #     file_name /report-[0-9]+\.csv/
  #     pick      ->(list) { list[-2] }
  #   end
  #
  class FTP < Stockboy::Provider

    # @!group Options

    # Host name or IP address for FTP server connection
    #
    # @!attribute [rw] host
    # @return [String]
    # @example
    #   host "ftp.example.com"
    #
    dsl_attr :host

    # Use a passive or active connection
    #
    # @!attribute [rw] passive
    # @return [Boolean]
    # @example
    #   passive true
    #
    dsl_attr :passive

    # User name for connection credentials
    #
    # @!attribute [rw] username
    # @return [String]
    # @example
    #   username "arthur"
    #
    dsl_attr :username

    # Password for connection credentials
    #
    # @!attribute [rw] password
    # @return [String]
    # @example
    #   password "424242"
    #
    dsl_attr :password

    # Use binary mode for file transfers
    #
    # @!attribute [rw] binary
    # @return [Boolean]
    # @example
    #   binary true
    #
    dsl_attr :binary

    # @macro provider.file_options
    dsl_attr :file_name
    dsl_attr :file_dir
    dsl_attr :file_newer, alias: :since
    dsl_attr :file_smaller
    dsl_attr :file_larger

    # @macro provider.pick_option
    dsl_attr :pick

    # @!endgroup

    # Initialize a new FTP provider
    #
    # @param [Hash] opts
    # @option opts :host     [String]
    # @option opts :username [String]
    # @option opts :password [String]
    # @option opts :passive  [Boolean]
    # @option opts :binary   [Boolean]
    # @macro provider.initialize.file_options
    # @yield instance for configuration
    #
    def initialize(opts={}, &block)
      super(opts, &block)
      @host         = opts[:host]
      @passive      = opts[:passive]
      @username     = opts[:username]
      @password     = opts[:password]
      @binary       = opts[:binary]
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
      errors.add_on_blank [:host, :file_name]
      errors.empty?
    end

    def fetch_data
      Net::FTP.open(host, username, password) do |ftp|
        begin
          ftp.binary = binary
          ftp.passive = passive
          ftp.chdir file_dir if file_dir
          file_listing = ftp.nlst.sort
          matching_file = pick_from file_listing.select(&file_name_matcher)
          validate_file(ftp, matching_file)
          if valid?
            logger.info "FTP getting file #{file_dir}/#{matching_file}"
            @data = ftp.get(matching_file,nil)
            logger.info "FTP got file #{file_dir}/#{matching_file} (#@data_size bytes)"
          end
        rescue Net::FTPError
          errors.add :response, ftp.last_response
          logger.warn ftp.last_response
        end
      end
      !@data.nil?
    end

    def file_name_matcher
      case file_name
      when Regexp
        ->(i) { i =~ file_name }
      when String
        ->(i) { ::File.fnmatch(file_name, i) }
      end
    end

    def validate_file(ftp, data_file)
      return errors.add :response, "No matching files" unless data_file
      validate_file_newer(ftp, data_file)
      validate_file_smaller(ftp, data_file)
      validate_file_larger(ftp, data_file)
    end

    def validate_file_newer(ftp, data_file)
      @data_time = ftp.mtime(data_file)
      if file_newer and @data_time < file_newer
        errors.add :response, "No new files since #{file_newer}"
      end
    end

    def validate_file_smaller(ftp, data_file)
      @data_size = ftp.size(data_file)
      if file_smaller and @data_size > file_smaller
        errors.add :response, "File size larger than #{file_smaller}"
      end
    end

    def validate_file_larger(ftp, data_file)
      @data_size = ftp.size(data_file)
      if file_larger and @data_size < file_larger
        errors.add :response, "File size smaller than #{file_larger}"
      end
    end
  end
end
