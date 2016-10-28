require 'net/ftp'

module Stockboy::Providers
  class FTP::FTPAdapter
    attr_reader :client

    def initialize(provider)
      @provider = provider
    end

    def open
      result = nil
      Net::FTP.open(@provider.host, @provider.username, @provider.password) do |ftp|
        @client = ftp
        client.binary = @provider.binary
        client.passive = @provider.passive
        result = yield self
      end
      result
    end

    def chdir(directory)
      client.chdir directory
    end

    def list_files
      client.nlst.sort
    end

    def delete(file_name)
      client.delete file_name
    end

    def download(file_name)
      client.get(file_name, nil)
    end

    def modification_time(file_name)
      client.mtime file_name
    end

    def size(file_name)
      client.size file_name
    end

    def self.exception_class
      Net::FTPError
    end
  end
end
