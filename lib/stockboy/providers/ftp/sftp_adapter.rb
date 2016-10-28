require 'net/sftp'

module Stockboy::Providers
  class FTP::SFTPAdapter
    attr_reader :client

    def initialize(provider)
      @provider = provider
      @file_dir = "."
    end

    def open
      result = nil
      Net::SFTP.start(@provider.host, @provider.username, password: @provider.password) do |sftp|
        @client = sftp
        result = yield self
      end
      result
    end

    def chdir(directory)
      @file_dir = ::File.join(directory, '')
    end

    def list_files
      client.dir.entries(@file_dir).map(&:name).sort
    end

    def delete(file_name)
      client.remove!(full_path(file_name))
    end

    def download(file_name)
      client.download!(full_path(file_name))
    end

    def full_path(file_name)
      ::File.join(@file_dir, file_name)
    end

    def modification_time(file_name)
      client.file.open(full_path(file_name)).stat.mtime
    end

    def size(file_name)
      client.file.open(full_path(file_name)).stat.size
    end

    def self.exception_class
      Net::SFTP::Exception
    end
  end
end
