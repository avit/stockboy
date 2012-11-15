require 'spec_helper'
require 'stockboy/providers/file'

module Stockboy
  describe Providers::File do

    it "should assign parameters" do
      subject.file_dir "fixtures/files"
      subject.file_name %r{import_20[1-9][0-9]-(0[1-9]|1[0-2])-([0-2][1-9]|3[0-1]).csv}
      subject.file_newer Date.today
      subject.file_smaller 1024**2
      subject.file_larger 1024
      subject.pick :first

      subject.file_dir.should == "fixtures/files"
      subject.file_name.should == %r{import_20[1-9][0-9]-(0[1-9]|1[0-2])-([0-2][1-9]|3[0-1]).csv}
      subject.file_newer.should == Date.today
      subject.file_smaller.should == 1024**2
      subject.file_larger.should == 1024
      subject.pick.should == :first
    end

    describe ".new" do
      it "has no errors" do
        subject.errors.messages.should be_empty
      end

      it "accepts block initialization" do
        subject = Providers::File.new{ |f| f.file_dir 'fixtures/files' }
        subject.file_dir.should == 'fixtures/files'
      end
    end

    describe "#data" do
      subject do
        Providers::File.new do |f|
          f.file_dir = RSpec.configuration.fixture_path.join("files")
        end
      end

      it "finds last matching file from string glob" do
        subject.file_name "test_data-*.csv"
        subject.data.should == "2012-02-02\n"
      end

      it "finds first matching file from string glob" do
        subject.file_name "test_data-*.csv"
        subject.pick :first
        subject.data.should == "2012-01-01\n"
      end

      it "finds last matching file from regex" do
        subject.file_name /test_data/
        subject.data.should == "2012-02-02\n"
      end
    end

  end
end
