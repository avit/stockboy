require 'spec_helper'
require 'stockboy/providers/ftp'

module Stockboy
  describe Providers::FTP do

    subject(:provider) do
      Stockboy::Providers::FTP.new do |ftp|
        ftp.host = "localhost.test"
        ftp.username = "a"
        ftp.password = "b"
        ftp.binary = true
        ftp.passive = true
        ftp.file_name = '*.csv'
      end
    end

    it "should assign parameters" do
      ftp = Stockboy::Providers::FTP.new
      ftp.host = "localhost.test"
      ftp.username = "uuu"
      ftp.password = "ppp"
      ftp.file_dir = "files/here"
      ftp.file_name = %r{import_20[1-9][0-9]-(0[1-9]|1[0-2])-([0-2][1-9]|3[0-1]).csv}

      ftp.host.should == "localhost.test"
      ftp.username.should == "uuu"
      ftp.password.should == "ppp"
      ftp.file_dir.should == "files/here"
      ftp.file_name.should == %r{import_20[1-9][0-9]-(0[1-9]|1[0-2])-([0-2][1-9]|3[0-1]).csv}
    end

    describe ".new" do
      it "has no errors" do
        subject.errors.messages.should be_empty
      end

      it "accepts block initialization" do
        ftp = Providers::FTP.new{ |f| f.host 'test2.local' }
        ftp.host.should == 'test2.local'
      end
    end

    describe "#client" do
      it "should open connection to host with username and password" do
        expect_connection

        connection = false
        provider.client { |f| connection = f }

        connection.should be_a Net::FTP
        connection.binary.should be_true
        connection.passive.should be_true
      end

      it "should return yielded result" do
        expect_connection

        result = provider.client { |_| "a_file_name.csv" }

        result.should == "a_file_name.csv"
      end
    end

    describe "#data" do
      it "adds an error on missing host" do
        provider.host = nil
        provider.data

        provider.errors.include?(:host).should be_true
      end

      it "adds an error on missing file_name" do
        provider.file_name = nil
        provider.data

        provider.errors.include?(:file_name).should be_true
      end

      it "downloads the last matching file" do
        net_ftp = expect_connection
        expect(net_ftp).to receive(:nlst).and_return ['20120101.csv', '20120102.csv']
        expect(net_ftp).to receive(:get).with('20120102.csv', nil).and_return "DATA"
        expect(provider).to receive(:validate_file).and_return true

        provider.data.should == "DATA"
      end

      it "skips old files" do
        net_ftp = expect_connection
        expect(net_ftp).to receive(:nlst).and_return ['20120101.csv', '20120102.csv']
        expect(net_ftp).to receive(:mtime).with('20120102.csv').and_return(Time.new(2009,01,01))
        expect(net_ftp).to_not receive(:get)

        provider.file_newer = Time.new(2010,1,1)

        provider.data.should be_nil
      end
    end

    describe "#matching_file" do
      it "does not change until cleared" do
        net_ftp = expect_connection
        expect(net_ftp).to receive(:nlst).and_return ["1.csv", "2.csv"]

        provider.matching_file.should == "2.csv"

        net_ftp = expect_connection
        expect(net_ftp).to receive(:nlst).and_return ["1.csv", "2.csv", "3.csv"]

        provider.matching_file.should == "2.csv"
        provider.clear
        provider.matching_file.should == "3.csv"
      end
    end

    def expect_connection(host="localhost.test", user="a", pass="b")
      net_ftp = Net::FTP.new
      expect(Net::FTP).to receive(:open).with(host, user, pass).and_yield(net_ftp)
      net_ftp
    end

  end
end
