require 'spec_helper'
require 'stockboy/translations/us_date.rb'

module Stockboy
  describe Translations::USDate do

    subject { described_class.new(:start) }

    describe "#call" do
      it "returns nil for an empty string" do
        result = subject.call stub(start: "")
        result.should be_nil
      end

      it "translates MM/DD/YYYY" do
        result = subject.call stub(start: "4/6/2013")
        result.should == Date.new(2013,4,6)
      end

      it "translates MM/DD/YY" do
        result = subject.call stub(start: "4/6/13")
        result.should == Date.new(2013,4,6)
      end

      it "translates MM-DD-YYYY" do
        result = subject.call stub(start: "4-6-2013")
        result.should == Date.new(2013,4,6)
      end

      it "translates MM-DD-YY" do
        result = subject.call stub(start: "4-6-13")
        result.should == Date.new(2013,4,6)
      end
    end

  end
end
