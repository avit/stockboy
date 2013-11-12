require 'spec_helper'
require 'stockboy/mapped_record'

module Stockboy
  describe MappedRecord do
    subject(:record) do
      MappedRecord.new(:full_name => 'Arthur Dent')
    end

    it "accesses initialized fields from hash" do
      record.full_name.should == 'Arthur Dent'
    end

    it "does not redefine accessor methods" do
      record1 = MappedRecord.new(:full_name => 'Arthur Dent')
      record2 = MappedRecord.new(:full_name => 'Arthur Dent')

      record1.method(:full_name).owner.should ==
      record2.method(:full_name).owner
    end

    it "only has its own accessor methods" do
      record1 = MappedRecord.new(:first_name => 'Arthur')
      record2 = MappedRecord.new(:last_name => 'Dent')

      record1.should_not respond_to(:last_name)
      record2.should_not respond_to(:first_name)
    end
  end
end
