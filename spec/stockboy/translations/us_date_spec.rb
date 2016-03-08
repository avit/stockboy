require 'spec_helper'
require 'stockboy/translations/us_date.rb'

module Stockboy
  describe Translations::USDate do

    subject { described_class.new(:start) }

    describe "#call" do
      it "returns nil for an empty string" do
        result = subject.call start: ""
        expect(result).to be nil
      end

      it "translates MM/DD/YYYY" do
        result = subject.call start: "4/6/2013"
        expect(result).to eq Date.new(2013,4,6)
      end

      it "translates MM/DD/YY" do
        result = subject.call start: "4/6/13"
        expect(result).to eq Date.new(2013,4,6)
      end

      it "translates MM-DD-YYYY" do
        result = subject.call start: "4-6-2013"
        expect(result).to eq Date.new(2013,4,6)
      end

      it "translates MM-DD-YY" do
        result = subject.call start: "4-6-13"
        expect(result).to eq Date.new(2013,4,6)
      end
    end

  end
end
