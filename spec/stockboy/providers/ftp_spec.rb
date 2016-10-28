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

      expect(ftp.host).to eq "localhost.test"
      expect(ftp.username).to eq "uuu"
      expect(ftp.password).to eq "ppp"
      expect(ftp.file_dir).to eq "files/here"
      expect(ftp.file_name).to eq %r{import_20[1-9][0-9]-(0[1-9]|1[0-2])-([0-2][1-9]|3[0-1]).csv}
    end

    describe ".new" do
      it "has no errors" do
        expect(subject.errors).to be_empty
      end

      it "accepts block initialization" do
        ftp = Providers::FTP.new{ |f| f.host 'test2.local' }
        expect(ftp.host).to eq 'test2.local'
      end
    end

    describe "#client" do
      it "should return yielded result" do
        expect_connection

        result = provider.client { |_| "a_file_name.csv" }

        expect(result).to eq "a_file_name.csv"
      end
    end

    describe "#data" do
      it "adds an error on missing host" do
        provider.host = nil
        provider.data

        expect(provider.errors.first).to include "host"
      end

      it "adds an error on missing file_name" do
        provider.file_name = nil
        provider.data

        expect(provider.errors.first).to include "file_name"
      end

      it "downloads the last matching file" do
        net_ftp = expect_connection
        expect(net_ftp).to receive(:list_files).and_return ['20120101.csv', '20120102.csv']
        expect(net_ftp).to receive(:download).with('20120102.csv').and_return "DATA"
        expect(provider).to receive(:validate_file).and_return true

        expect(provider.data).to eq "DATA"
      end

      it "skips old files" do
        net_ftp = expect_connection
        expect(net_ftp).to receive(:list_files).and_return ['20120101.csv', '20120102.csv']
        expect(net_ftp).to receive(:modification_time).with('20120102.csv').and_return(Time.new(2009,01,01))
        expect(net_ftp).to receive(:size).with('20120102.csv').and_return(Time.new(2009,01,01))
        expect(net_ftp).to_not receive(:download)

        provider.file_newer = Time.new(2010,1,1)
        expect(provider.data).to be nil
      end
    end

    describe "#matching_file" do
      it "does not change until cleared" do
        net_ftp = expect_connection
        expect(net_ftp).to receive(:list_files).and_return ["1.csv", "2.csv"]

        expect(provider.matching_file).to eq "2.csv"

        net_ftp = expect_connection
        expect(net_ftp).to receive(:list_files).and_return ["1.csv", "2.csv", "3.csv"]

        expect(provider.matching_file).to eq "2.csv"
        provider.clear
        expect(provider.matching_file).to eq "3.csv"
      end
    end

    describe "#delete_data" do
      it "should raise an error when called blindly" do
        expect_any_instance_of(provider.adapter_class).to_not receive(:delete)
        expect { provider.delete_data }.to raise_error Stockboy::OutOfSequence
      end

      it "should delete the matching file" do
        net_ftp = expect_connection
        expect(net_ftp).to receive(:list_files).and_return ["1.csv", "2.csv"]

        expect(provider.matching_file).to eq "2.csv"

        net_ftp = expect_connection
        expect(net_ftp).to receive(:delete).with("2.csv")

        expect(provider.delete_data).to eq "2.csv"
      end
    end

    def expect_connection
      adapter = instance_double(provider.adapter_class)
      expect(adapter).to receive(:open).and_yield(adapter)

      expect(provider.adapter_class).to receive(:new).with(provider).and_return adapter
      adapter
    end

  end
end
