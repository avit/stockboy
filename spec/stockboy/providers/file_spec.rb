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

      expect(provider.file_dir).to eq "fixtures/files"
      expect(provider.file_name).to eq %r{import_20[1-9][0-9]-(0[1-9]|1[0-2])-([0-2][1-9]|3[0-1]).csv}
      expect(provider.file_newer).to eq Date.today
      expect(provider.file_smaller).to eq 1024**2
      expect(provider.file_larger).to eq 1024
      expect(provider.pick).to eq :first
    end

    describe ".new" do
      it "has no errors" do
        expect(provider.errors).to be_empty
      end

      it "accepts block initialization" do
        provider = Providers::File.new{ |f| f.file_dir 'fixtures/files' }
        expect(provider.file_dir).to eq 'fixtures/files'
      end
    end

    describe "#matching_file" do
      let(:provider) { Providers::File.new(file_dir: fixture_path("files")) }
      subject(:matching_file) { provider.matching_file }

      context "with a matching string" do
        before { provider.file_name = "test_data-*" }
        it "returns the full path to the matching file name" do
          should end_with "fixtures/files/test_data-20120202.csv"
        end
      end

      context "with a matching regex" do
        before { provider.file_name = /^test_data-\d+/ }
        it "returns the full path to the matching file name" do
          should end_with "fixtures/files/test_data-20120202.csv"
        end
      end

      context "with an unmatched string" do
        before { provider.file_name = "missing" }
        it { should be nil }
      end
    end

    describe "#data" do
      subject(:provider) { Providers::File.new(file_dir: fixture_path("files")) }

      it "fails with an error if the file doesn't exist" do
        provider.file_name = "missing-file.csv"
        expect(provider.data).to be nil
        expect(provider.valid?).to be false
        expect(provider.errors.first).to match /not found/
      end

      it "finds last matching file from string glob" do
        provider.file_name = "test_data-*.csv"
        expect(provider.data).to eq "2012-02-02\n"
      end

      it "finds first matching file from string glob" do
        provider.file_name = "test_data-*.csv"
        provider.pick = :first
        expect(provider.data).to eq "2012-01-01\n"
      end

      it "finds last matching file from regex" do
        provider.file_name = /test_data/
        expect(provider.data).to eq "2012-02-02\n"
      end

      context "metadata validation" do
        before { provider.file_name = '*.csv' }
        let(:recently)  { Time.now - 60 }
        let(:last_week) { Time.now - 86400 }

        it "skips old files with :since" do
          expect_any_instance_of(::File).to receive(:mtime).and_return last_week
          provider.since = recently
          expect(provider.data).to be nil
          expect(provider.errors.first).to eq "no new files since #{recently}"
        end

        it "skips large files with :file_smaller" do
          expect_any_instance_of(::File).to receive(:size).and_return 1001
          provider.file_smaller = 1000
          expect(provider.data).to be nil
          expect(provider.errors.first).to eq "file size larger than 1000"
        end

        it "skips small files with :file_larger" do
          expect_any_instance_of(::File).to receive(:size).and_return 999
          provider.file_larger = 1000
          expect(provider.data).to be nil
          expect(provider.errors.first).to eq "file size smaller than 1000"
        end
      end
    end

    describe ".delete_data" do
      let(:target)     { ::Tempfile.new(['delete', '.csv']) }
      let(:target_dir) { File.dirname(target) }
      let(:pick_same)  { ->(best, this) { this == target.path ? this : best } }

      subject(:provider) do
        Providers::File.new(file_name: 'delete*.csv', file_dir: target_dir, pick: pick_same)
      end

      it "should raise an error when called blindly" do
        expect { provider.delete_data }.to raise_error Stockboy::OutOfSequence
      end

      it "should call delete on the matched file" do
        provider.matching_file

        non_matching_duplicate = ::Tempfile.new(['delete', '.csv'])

        expect(::File).to receive(:delete).with(target.path)
        provider.delete_data
      end
    end

  end
end
