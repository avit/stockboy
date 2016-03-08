require 'spec_helper'
require 'stockboy/translations/uk_date.rb'

module Stockboy
  describe Translations::UKDate do

    subject { described_class.new(:start) }

    describe "#call" do
      it "returns nil for an empty string" do
        result = subject.call start: ""
        expect(result).to be nil
      end

      it "translates DD/MM/YYYY" do
        result = subject.call start: "15/4/2013"
        expect(result).to eq Date.new(2013,4,15)
      end

      it "translates DD/MM/YY" do
        result = subject.call start: "15/4/13"
        expect(result).to eq Date.new(2013,4,15)
      end

      it "translates DD-MM-YYYY" do
        result = subject.call start: "15-4-2013"
        expect(result).to eq Date.new(2013,4,15)
      end

      it "translates DD-MM-YY" do
        result = subject.call start: "15-4-13"
        expect(result).to eq Date.new(2013,4,15)
      end
    end

  end
end
