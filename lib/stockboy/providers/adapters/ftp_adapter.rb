require 'net/ftp'

module Stockboy
  module Providers
    module Adapters
      class Stockboy::Providers::Adapters::FTPAdapter
        attr_reader :client

        def initialize(provider)
          @provider = provider

        end

        def open
          Net::FTP.open(@provider.host, @provider.username, @provider.password) do |ftp|
            puts "open connection"
            @client = ftp
            client.binary = @provider.binary
            client.passive = @provider.passive
            result = yield self
            puts "close connection"
            result
          end
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
  end
end
