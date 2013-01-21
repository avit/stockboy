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
        )

        reader.format.should == :xlsx
        reader.sheet.should  == 'Sheet 42'
      end

      it "configures with a block" do
        reader = described_class.new do
          format :xlsx
          sheet 'Sheet 42'
        end

        reader.format.should == :xlsx
        reader.sheet.should  == 'Sheet 42'
      end
    end

    describe "#parse" do
      let(:content) { File.read(RSpec.configuration.fixture_path.join(fixture_file)) }

      context "with an XLS file" do
        let(:fixture_file) { 'spreadsheets/test_data.xls' }

        it "returns an array of hashes" do
          reader = described_class.new(format: :xls)
          data = reader.parse(content)

          data.should_not be_empty
          data.each { |i| i.should be_a Hash }
        end
      end
    end

    pending "#sheet", "Hard to test this due to roo. Needs a test case with fixtures" do
      let(:sheets)      { ['Towels', 'Lemons'] }
      let(:expectation) { mock(:spreadsheet, sheets: sheets).should_receive(:default_sheet=) }
      let(:spreadsheet) { expectation }
      before { subject.stub!(:with_spreadsheet).and_yield(spreadsheet) }

      context "with :first" do
        let(:spreadsheet) { expectation.with('Towels') }

        it "calls on first sheet by name" do
          subject.sheet = :first
          subject.parse ""
        end
      end

      context "with a string" do
        let(:spreadsheet) { expectation.with('Towels') }

        it "passes unchanged" do
          subject.sheet = 'Towels'
          subject.parse ""
        end
      end

      context "with an integer" do
        let(:spreadsheet) { expectation.with('Towels') }

        it "gets sheet name" do
          subject.sheet = 1
          subject.parse ""
        end
      end
    end

  end
end
