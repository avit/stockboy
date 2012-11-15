require 'spec_helper'
require 'stockboy/readers/csv'

module Stockboy
  describe Readers::CSV do
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
      subject(:records) do
        Readers::CSV.new(headers: true).parse <<-EOF.gsub(/^ {8}/,'')
        id,name
        42,Arthur Dent
        EOF
      end

      it "returns an array of records" do
        records[0].should == {"id" => "42", "name" => "Arthur Dent"}
      end
    end
  end
end
