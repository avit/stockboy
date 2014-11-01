require 'spec_helper'
require 'stockboy/readers/csv'

module Stockboy
  describe Readers::CSV do

    subject(:reader) { Stockboy::Readers::CSV.new }

    describe "default options" do
      its(:row_sep)          { should be nil }
      its(:col_sep)          { should be nil }
      its(:quote_char)       { should be nil }
      its(:headers)          { should be true }
      its(:skip_header_rows) { should == 0 }
      its(:skip_footer_rows) { should == 0 }
    end

    describe "initialize" do
      it "configures options with argument hash" do
        reader = Readers::CSV.new(col_sep: '|')
        reader.col_sep.should == '|'
      end

      it "configures options with a block" do
        reader = Readers::CSV.new do
          encoding 'ISO-8859-1'
          col_sep "|"
          skip_header_rows 2
          skip_footer_rows 1
        end

        reader.col_sep.should == '|'
        reader.skip_header_rows.should == 2
        reader.skip_footer_rows.should == 1
      end
    end

    describe "#parse" do
      it "returns an array of records" do
        records = reader.parse "id,name\n42,Arthur Dent"

        records[0].should == {"id" => "42", "name" => "Arthur Dent"}
      end

      it "strips null bytes from empty fields (MSSQL BCP exports)" do
        reader.col_sep = '|'
        reader.headers = %w[city state country]
        records = reader.parse "Vancouver|\x00|Canada"

        records.should ==
          [{"city" => "Vancouver", "state" => nil, "country" => "Canada"}]
      end

      it "scrubs invalid encoding characters in Unicode" do
        reader.headers = %w[depart arrive]
        reader.encoding = 'UTF-8'
        garbage = 191.chr.force_encoding('UTF-8')
        data = "Z#{garbage}rich,Genève"
        reader.parse(data).should ==
          [{"depart" => "Z\u{FFFD}rich", "arrive" => "Genève"}]
      end

      it "strips preamble header rows" do
        reader.skip_header_rows = 2
        data = "IGNORE\r\nCOMMENTS\r\nid,name\r\n42,Arthur Dent"
        records = reader.parse data

        records[0].should == {"id" => "42", "name" => "Arthur Dent"}
      end

      it "shares hash key instances between records" do
        records = reader.parse "id,name\n42,Arthur Dent\n999,Zaphod"
        records[0].keys[0].should be records[1].keys[0]
      end
    end
  end
end
