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
          headers: %w(X Y Z)
        )

        expect(reader.format).to eq :xlsx
        expect(reader.sheet).to  eq 'Sheet 42'
        expect(reader.header_row).to eq 5
        expect(reader.headers).to eq %w(X Y Z)
      end

      it "configures with a block" do
        reader = described_class.new do
          format :xlsx
          sheet 'Sheet 42'
          header_row 5
          headers %w(X Y Z)
        end

        expect(reader.format).to eq :xlsx
        expect(reader.sheet).to  eq 'Sheet 42'
        expect(reader.header_row).to eq 5
        expect(reader.headers).to eq %w(X Y Z)
      end
    end

    describe "#parse" do
      let(:content) { File.read(fixture_path fixture_file) }

      context "with an XLS file" do
        let(:fixture_file) { 'spreadsheets/test_data.xls' }

        it "returns an array of hashes" do
          reader = described_class.new(format: :xls)
          data = reader.parse(content)

          expect(data).not_to be_empty
          data.each { |i| expect(i).to be_a Hash }
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
    end

    describe "#sheet", skip: "Hard to test this due to roo. Needs a test case with fixtures" do
      let(:sheets)      { ['Towels', 'Lemons'] }
      let(:be_selected) { receive(:default_sheet=) }
      let(:spreadsheet) { double(:spreadsheet, sheets: sheets) }
      before { allow(subject).to receive(:with_spreadsheet).and_yield(spreadsheet) }

      context "with :first" do
        before { expect(spreadsheet).to be_selected.with('Towels') }

        it "calls on first sheet by name" do
          subject.sheet = :first
          subject.parse ""
        end
      end

      context "with a string" do
        before { expect(spreadsheet).to be_selected.with('Towels') }

        it "passes unchanged" do
          subject.sheet = 'Towels'
          subject.parse ""
        end
      end

      context "with an integer" do
        before { expect(spreadsheet).to be_selected.with('Towels') }

        it "gets sheet name" do
          subject.sheet = 1
          subject.parse ""
        end
      end
    end

  end
end
