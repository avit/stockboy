require 'spec_helper'
require 'stockboy/readers/json'

module Stockboy
  describe Readers::JSON do

    subject(:reader) { Stockboy::Readers::JSON.new }

    describe "#parse" do
      it "returns an array of records" do
        records = reader.parse '{"id": "42", "name": "Arthur Dent"}'

        expect(records).to eq({"id" => "42", "name" => "Arthur Dent"})
      end

    end
  end
end
