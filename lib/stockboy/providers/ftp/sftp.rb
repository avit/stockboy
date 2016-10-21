require 'net/sftp'
require 'pry'

class SFTPAdapter
  attr_accessor :client

  def initialize(provider)
    @provider = provider
  end

  def open
    result = nil
    Net::SFTP.start(@provider.host, @provider.username, password: @provider.password) do |sftp|
      puts 'open connection'
      @client = sftp
      result = yield self
      puts 'close connection'
    end
    result
  end

  def chdir(directory)
    @file_dir = directory.nil? || directory.empty? ?  '/' : normalize_file_dir(directory)
  end

  def list_files
    client.dir.entries(@file_dir).map { |e| e.name }
  end

  def delete(file_name)
    client.remove!("#{@file_dir}#{file_name}")
  end

  def download(file_name)
    file = client.file.open("#{@file_dir}#{file_name}")
    data = file.gets
    file.close
    data
  end

  def modification_time(file_name)
    client.file.open("#{@file_dir}#{file_name}").stat.mtime
  end

  def size(file_name)
    client.file.open("#{@file_dir}#{file_name}").stat.size
  end

  def self.exception_class
    Net::SFTP::StatusException
  end

  private

  def normalize_file_dir(file_dir)

    if file_dir[0] == "/" && file_dir[-1] == "/"
      file_dir
    elsif file_dir[0] != "/" && file_dir[-1] == "/"
      "/" + file_dir
    elsif file_dir[0] == "/" && file_dir[-1] != "/"
      file_dir + "/"
    else
      "/" + file_dir + "/"
    end
  end
end
