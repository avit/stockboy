require 'net/ftp'

class FTPAdapter
  attr_accessor :client

  def initialize(host, username, password, options={})
    @client = Net::FTP.open(host, username, password)
    client.binary = options['binary']
    client.passive = options['passive']
    client.chdir options[:file_dir] if options[:file_dir]
  end

  def list_files
    client.nlst
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
end
