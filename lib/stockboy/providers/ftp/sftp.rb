require 'net/sftp'

class SFTPAdapter
  attr_accessor :client

  def initialize(host, username, password, options={})
    @client = Net::SFTP.start(host, username, password: password)
    @file_dir = options[:file_dir].nil? || options[:file_dir].blank? ?  '/' : normalize_file_dir(options[:file_dir])
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

  def exception_class
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