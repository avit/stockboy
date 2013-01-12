require 'spec_helper'
require 'stockboy/readers/spreadsheet'

module Stockboy
  describe Readers::Spreadsheet do

    subject(:reader) { Stockboy::Readers::Spreadsheet.new }

    describe "default params" do
      its(:format)           { should == :xls }
      its(:sheet)            { should == :first }
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

    pending "#sheet" do
      let(:sheets) { subject.target.sheets }

      context "with a symbol" do
        before       { subject.sheet = :last }

        it "calls on sheets" do
          subject.target.should_receive(:default_sheet=)
                        .with('Last Sheet Name')
          subject.parse ""
        end
      end

      context "with a string" do
        before { subject.sheet = 'Second Sheet Name' }

        it "passes unchanged" do
          subject.target.should_receive(:default_sheet=)
                        .with('Second Sheet Name')
          subject.parse ""
        end
      end

      context "with an integer" do
        before { subject.sheet = 0 }

        it "gets sheet name" do
          subject.target.should_receive(:default_sheet=)
                        .with('First Sheet Name')
          subject.parse ""
        end
      end
    end

  end
end
