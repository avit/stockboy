require 'spec_helper'
require 'stockboy/readers/fixed_width'

module Stockboy
  describe Readers::FixedWidth do

    let(:headers_hash) { {first: 10, last: 10, age: 4, sex: 2, planet: 10} }
    let(:blank_row)    { "                                    \r\n" }
    let(:data) {
      "Arthur    Dent      42  M Human     \r\n" +
      "Ford      Prefect   44  M Betelgeuse\r\n"
    }

    it "parses based on column widths" do
      reader = described_class.new(headers: [10, 10, 4, 2, 10])
      reader.parse(data).should == [
        {0 => "Arthur", 1 => "Dent", 2 => "42", 3 => "M", 4 => "Human"},
        {0 => "Ford", 1 => "Prefect", 2 => "44", 3 => "M", 4 => "Betelgeuse"}
      ]
    end

    it "parses based on a hash" do
      reader = described_class.new(headers: headers_hash)
      reader.parse(data).should == [
        {first: "Arthur", last: "Dent", age: "42", sex: "M", planet: "Human"},
        {first: "Ford", last: "Prefect", age: "44", sex: "M", planet: "Betelgeuse"}
      ]
    end

    it "skips blank rows" do
      reader = described_class.new(headers: headers_hash)
      records = reader.parse(blank_row + data + blank_row)
      records.first[:age].should == '42'
      records.last[:age].should == '44'
    end

    it "skips number of specified header rows" do
      reader = described_class.new(headers: headers_hash)
      reader.skip_header_rows = 1
      records = reader.parse("REPORT\r\n" + data)
      records.first[:age].should == '42'
    end

    it "skips number of specified footer rows" do
      reader = described_class.new(headers: headers_hash)
      reader.skip_footer_rows = 2
      records = reader.parse(data + "SUBTOTAL\r\nTOTAL\r\n")
      records.last[:age].should == '44'
    end

  end
end
