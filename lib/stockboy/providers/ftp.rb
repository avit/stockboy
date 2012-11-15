require 'stockboy/provider'
require 'net/ftp'

module Stockboy::Providers
  class FTP < Stockboy::Provider

    dsl_attrs(
      :host,
      :username,
      :password,
      :binary,
      :file_name,
      :file_dir,
      :file_newer,
      :file_smaller,
      :file_larger,
      :pick
    )

    def initialize(opts={}, &block)
      super(opts, &block)
      @host         = opts[:host]
      @username     = opts[:username]
      @password     = opts[:password]
      @binary       = opts[:binary]
      @file_dir     = opts[:file_dir]
      @file_name    = opts[:file_name]
      @file_newer   = opts[:file_newer]
      @file_smaller = opts[:file_smaller]
      @file_larger  = opts[:file_larger]
      @pick         = opts[:pick] || :last
      instance_eval(&block) if block_given?
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
          ftp.chdir file_dir if file_dir
          matching_file = pick_file_from ftp.nlst.select(&file_name_matcher)
          validate_file(ftp, matching_file)
          @data = ftp.get(matching_file,nil) if valid?
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

    def pick_file_from(list)
      case @pick
      when Symbol
        list.public_send @pick
      when Proc
        list.detect &@pick
      end
    end

    def validate_file(ftp, data_file)
      validate_file_newer(ftp, data_file)
      validate_file_smaller(ftp, data_file)
      validate_file_larger(ftp, data_file)
    end

    def validate_file_newer(ftp, data_file)
      @data_time ||= ftp.mtime(data_file)
      if file_newer && @data_time < file_newer
        errors.add :response, "No new files since #{file_newer}"
      end
    end

    def validate_file_smaller(ftp, data_file)
      @data_size ||= ftp.size(data_file)
      if file_smaller && @data_size > file_smaller
        errors.add :response, "File size larger than #{file_smaller}"
      end
    end

    def validate_file_larger(ftp, data_file)
      @data_size ||= ftp.size(data_file)
      if file_larger && @data_size < file_larger
        errors.add :response, "File size smaller than #{file_larger}"
      end
    end
  end
end
