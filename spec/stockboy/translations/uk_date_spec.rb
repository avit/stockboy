require 'spec_helper'
require 'stockboy/translations/uk_date.rb'

module Stockboy
  describe Translations::UKDate do

    subject { described_class.new(:start) }

    describe "#call" do
      it "returns nil for an empty string" do
        result = subject.call start: ""
        result.should be_nil
      end

      it "translates DD/MM/YYYY" do
        result = subject.call start: "15/4/2013"
        result.should == Date.new(2013,4,15)
      end

      it "translates DD/MM/YY" do
        result = subject.call start: "15/4/13"
        result.should == Date.new(2013,4,15)
      end

      it "translates DD-MM-YYYY" do
        result = subject.call start: "15-4-2013"
        result.should == Date.new(2013,4,15)
      end

      it "translates DD-MM-YY" do
        result = subject.call start: "15-4-13"
        result.should == Date.new(2013,4,15)
      end
    end

  end
end
