require 'spec_helper'
require 'stockboy/source_record'

module Stockboy
  describe SourceRecord do
    subject(:record) do
      SourceRecord.new({:full_name => 'Arthur Dent'},
                       {3 => 'Arthur Dent'})
    end

    it "accesses initialized fields from hash" do
      expect(record.full_name).to eq 'Arthur Dent'
    end

    it "accesses source field names" do
      expect(record[3]).to eq 'Arthur Dent'
    end
  end
end
