require 'spec_helper'
require 'stockboy/readers/csv'

module Stockboy
  describe Readers::CSV do

    subject :reader

    describe "default params" do
      its(:row_sep)          { should be_nil }
      its(:col_sep)          { should be_nil }
      its(:quote_char)       { should be_nil }
      its(:headers)          { should be_true }
    end

    describe "initialize" do
      it "configures with params" do
        reader = Readers::CSV.new(col_sep: '|')
        reader.col_sep.should == '|'
      end

      it "configures with a block" do
        reader = Readers::CSV.new do
          col_sep "|"
        end

        reader.col_sep.should == '|'
      end
    end

    describe "#parse" do
      it "returns an array of records" do
        records = reader.parse "id,name\n42,Arthur Dent"

        records[0].should == {"id" => "42", "name" => "Arthur Dent"}
      end

      it "strips null bytes from empty fields (MSSQL BCP exports)" do
        reader.options[:col_sep] = '|'
        reader.options[:headers] = %w[city state country]
        records = reader.parse "Vancouver|\x00|Canada"

        records.should ==
          [{"city" => "Vancouver", "state" => nil, "country" => "Canada"}]
      end

      it "strips preamble header rows" do
        reader.skip_header_rows = 2
        data = "IGNORE\r\nCOMMENTS\r\nid,name\r\n42,Arthur Dent"
        records = reader.parse data

        records[0].should == {"id" => "42", "name" => "Arthur Dent"}
      end
    end
  end
end
