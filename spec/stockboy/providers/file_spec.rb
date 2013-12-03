require 'spec_helper'
require 'stockboy/providers/file'

module Stockboy
  describe Providers::File do
    subject(:provider) { Stockboy::Providers::File.new }

    it "should assign parameters" do
      provider.file_dir = "fixtures/files"
      provider.file_name = %r{import_20[1-9][0-9]-(0[1-9]|1[0-2])-([0-2][1-9]|3[0-1]).csv}
      provider.file_newer = Date.today
      provider.file_smaller = 1024**2
      provider.file_larger = 1024
      provider.pick = :first

      provider.file_dir.should == "fixtures/files"
      provider.file_name.should == %r{import_20[1-9][0-9]-(0[1-9]|1[0-2])-([0-2][1-9]|3[0-1]).csv}
      provider.file_newer.should == Date.today
      provider.file_smaller.should == 1024**2
      provider.file_larger.should == 1024
      provider.pick.should == :first
    end

    describe ".new" do
      it "has no errors" do
        provider.errors.messages.should be_empty
      end

      it "accepts block initialization" do
        provider = Providers::File.new{ |f| f.file_dir 'fixtures/files' }
        provider.file_dir.should == 'fixtures/files'
      end
    end

    describe "#matching_file" do
      subject(:provider) do
        Providers::File.new do |f|
          f.file_dir = RSpec.configuration.fixture_path.join("files")
        end
      end

      it "returns the full path to the matching file name" do
        provider.file_name = "test_data-*"
        provider.matching_file.should end_with "fixtures/files/test_data-20120202.csv"
      end
    end

    describe "#data" do
      subject(:provider) do
        Providers::File.new do |f|
          f.file_dir = RSpec.configuration.fixture_path.join("files")
        end
      end

      it "fails with an error if the file doesn't exist" do
        provider.file_name = "missing-file.csv"
        provider.data.should be_nil
        provider.valid?.should == false
        provider.errors[:base].should_not be_empty
      end

      it "finds last matching file from string glob" do
        provider.file_name = "test_data-*.csv"
        provider.data.should == "2012-02-02\n"
      end

      it "finds first matching file from string glob" do
        provider.file_name = "test_data-*.csv"
        provider.pick = :first
        provider.data.should == "2012-01-01\n"
      end

      it "finds last matching file from regex" do
        provider.file_name = /test_data/
        provider.data.should == "2012-02-02\n"
      end

      context "with :since validation" do
        let(:recently) { Time.now - 60 }

        it "skips old files" do
          expect_any_instance_of(::File).to receive(:mtime).and_return Time.now - 86400
          provider.file_dir = RSpec.configuration.fixture_path.join("files")
          provider.file_name = '*.csv'
          provider.since = recently

          provider.data.should be_nil
          provider.errors[:response].should include "No new files since #{recently}"
        end
      end
    end

    describe ".delete_data" do
      let(:target)       { ::Tempfile.new(['delete', '.csv']) }
      let(:target_dir)   { File.dirname(target) }
      subject(:provider) { Providers::File.new(file_name: 'delete*.csv', file_dir: target_dir) }

      after do
        target.unlink
      end

      it "should raise an error when called blindly" do
        expect_any_instance_of(::File).to_not receive(:delete)
        expect { provider.delete_data }.to raise_error Stockboy::OutOfSequence
      end

      it "should call delete on the matched file" do
        provider.matching_file

        expect(::File).to receive(:delete).with(target.path)
        provider.delete_data
      end
    end

  end
end
