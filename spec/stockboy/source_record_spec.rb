require 'spec_helper'
require 'stockboy/source_record'

module Stockboy
  describe SourceRecord do
    subject(:record) do
      SourceRecord.new({:full_name => 'Arthur Dent'},
                       {3 => 'Arthur Dent'})
    end

    it "accesses initialized fields from hash" do
      record.full_name.should == 'Arthur Dent'
    end

    it "accesses source field names" do
      record[3].should == 'Arthur Dent'
    end
  end
end
