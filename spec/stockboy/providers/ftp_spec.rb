require 'spec_helper'
require 'stockboy/providers/ftp'

module Stockboy
  describe Providers::FTP do

    it "should assign parameters" do
      subject.host = "localhost.test"
      subject.username = "uuu"
      subject.password = "ppp"
      subject.file_dir = "files/here"
      subject.file_name = %r{import_20[1-9][0-9]-(0[1-9]|1[0-2])-([0-2][1-9]|3[0-1]).csv}

      subject.host.should == "localhost.test"
      subject.username.should == "uuu"
      subject.password.should == "ppp"
      subject.file_dir.should == "files/here"
      subject.file_name.should == %r{import_20[1-9][0-9]-(0[1-9]|1[0-2])-([0-2][1-9]|3[0-1]).csv}
    end

    describe ".new" do
      it "has no errors" do
        subject.errors.messages.should be_empty
      end

      it "accepts block initialization" do
        subject = Providers::FTP.new{ |f| f.host 'test2.local' }
        subject.host.should == 'test2.local'
      end
    end

    describe "#data" do
      subject do
        Providers::FTP.new do |f|
          f.host = 'localhost.test'
          f.username = 'a'
          f.password = 'b'
          f.file_name = '*.csv'
        end
      end

      let!(:ftp) { mock(:ftp).as_null_object }

      def stub_ftp
        ::Net::FTP.should_receive(:open)
                  .with('localhost.test', 'a', 'b')
                  .and_yield(ftp)
      end

      it "adds an error on missing host" do
        subject.host = nil
        subject.data

        subject.errors.include?(:host).should be_true
      end

      it "adds an error on missing file_name" do
        subject.file_name = nil
        subject.data

        subject.errors.include?(:file_name).should be_true
      end

      it "downloads the last matching file" do
        stub_ftp
        ftp.stub!(:nlst).and_return ['20120101.csv', '20120102.csv']
        ftp.should_receive(:get).with('20120102.csv', nil)
        subject.stub(:validate_file).and_return true

        subject.data
      end

      it "skips old files" do
        stub_ftp
        ftp.stub!(:nlst).and_return ['20120101.csv', '20120102.csv']
        ftp.should_receive(:mtime)
           .with('20120102.csv')
           .and_return(Time.new(2009,01,01))
        ftp.should_not_receive(:get)

        subject.file_newer = Time.new(2010,1,1)

        subject.data.should be_nil
      end
    end

  end
end
