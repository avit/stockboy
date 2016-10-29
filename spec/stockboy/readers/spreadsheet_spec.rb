require 'spec_helper'
require 'stockboy/readers/spreadsheet'

module Stockboy
  describe Readers::Spreadsheet do

    subject(:reader) { Stockboy::Readers::Spreadsheet.new }

    describe "default options" do
      its(:format) { should == :xls }
      its(:sheet)  { should == :first }
    end


    describe "#initialize" do
      it "configures with hash parameter" do
        reader = described_class.new(
          format:  :xlsx,
          sheet:   'Sheet 42',
          header_row: 5,
          headers: %w(X Y Z),
          options: {packed: :zip}
        )

        expect(reader.format).to eq :xlsx
        expect(reader.sheet).to  eq 'Sheet 42'
        expect(reader.header_row).to eq 5
        expect(reader.headers).to eq %w(X Y Z)
        expect(reader.options).to eq({packed: :zip})
      end

      it "configures with a block" do
        reader = described_class.new do
          format :xlsx
          sheet 'Sheet 42'
          header_row 5
          headers %w(X Y Z)
          options({packed: :zip})
        end

        expect(reader.format).to eq :xlsx
        expect(reader.sheet).to  eq 'Sheet 42'
        expect(reader.header_row).to eq 5
        expect(reader.headers).to eq %w(X Y Z)
        expect(reader.options).to eq({packed: :zip})
      end
    end

    describe "#parse" do
      let(:content) { File.read(fixture_path fixture_file) }

      context "with an XLS file" do
        let(:fixture_file) { 'spreadsheets/test_data.xls' }

        it "uses line 1 for header names and line 2 for first row by default" do
          reader = described_class.new(format: :xls)
          data = reader.parse(content)

          expect(data.first).to eq({"Name" => "Arthur Dent", "Age" => 42})
          expect(data.last).to eq({"Name" => "Marvin", "Age" => 9999999})
        end

        it "Uses line 1 for first data row if headers are given" do
          reader = described_class.new(format: :xls, headers: ["id", "years"])
          data = reader.parse(content)

          expect(data.first).to eq({"id" => "Name", "years" => "Age"})
          expect(data.last).to eq({"id" => "Marvin", "years" => 9999999})
        end
      end

      context "underlying gem other options" do
        let(:fixture_file) { 'spreadsheets/test_data.xls.zip' }

        it "are passed to underlying library" do
          reader = described_class.new(format: :xls, options: {packed: :zip, file_warning: :ignore})

          data = reader.parse(content)
          expect(data).to be_an Array
        end
      end

      context "with blank line options" do
        let(:fixture_file) { 'spreadsheets/test_row_options.xls' }

        it "starts on the given first row" do
          reader = described_class.new(format: :xls, first_row: 6)
          data = reader.parse(content)

          expect(data.first.values).to eq ["Arthur Dent", 42]
        end

        it "ends on the given last row counting backwards" do
          reader = described_class.new(format: :xls, last_row: -3)
          data = reader.parse(content)

          expect(data.last.values).to eq ["Marvin", 9999999]
        end

        it "ends on the given last row counting upwards" do
          reader = described_class.new(format: :xls, last_row: 9)
          data = reader.parse(content)

          expect(data.last.values).to eq ["Ford", 40]
        end
      end

      context "with non-first header row" do
        let(:fixture_file) { 'spreadsheets/test_row_options.xls' }

        it "can use a different header_row" do
          reader = described_class.new(format: :xls, header_row: 4)
          data = reader.parse(content)

          expect(data.first).to eq({"Name" => nil, "Age" => nil})
        end

        it "can set both header_row and first_row" do
          reader = described_class.new(format: :xls, header_row: 4, first_row: 6)
          data = reader.parse(content)

          expect(data.first).to eq({"Name" => "Arthur Dent", "Age" => 42})
        end
      end
    end

    describe "#sheet" do
      let(:reader) { described_class.new(format: :xls) }
      let(:fixture_file) { 'spreadsheets/test_data_sheets.xls' }
      let(:content) { File.read(fixture_path fixture_file) }

      it "can specify :last sheet" do
        reader = described_class.new(format: :xls, sheet: :last)
        data = reader.parse content

        expect(data.first.values).to eq(["Earth", "Mostly Harmless"])
      end

      it "can specify sheet by name" do
        reader = described_class.new(format: :xls, sheet: 'Planets')
        data = reader.parse content

        expect(data.first.values).to eq(["Earth", "Mostly Harmless"])
      end

      it "can specify sheet by number" do
        reader = described_class.new(format: :xls, sheet: 2)
        data = reader.parse content

        expect(data.first.values).to eq(["Earth", "Mostly Harmless"])
      end
    end

  end
end
