require 'spec_helper'

module Stockboy
  describe MappedRecord do
    subject(:record) do
      MappedRecord.new(:full_name => 'Arthur Dent')
    end

    it "accesses initialized fields from hash" do
      record.full_name.should == 'Arthur Dent'
    end
  end
end
