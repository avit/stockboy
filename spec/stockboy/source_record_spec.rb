require 'spec_helper'

module Stockboy
  describe SourceRecord do
    subject(:record) do
      SourceRecord.new({:full_name => 'Arthur Dent'},
                       {'FIELD1' => 'Arthur Dent'})
    end

    it "accesses initialized fields from hash" do
      record.full_name.should == 'Arthur Dent'
    end

    it "accesses source field names" do
      record['FIELD1'].should == 'Arthur Dent'
    end
  end
end
