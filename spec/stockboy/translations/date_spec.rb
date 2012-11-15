require 'spec_helper'
require 'stockboy/translations/date'

module Stockboy
  describe Translations::Date do

    subject { described_class.new(:start) }

    describe "#call" do
      it "returns nil for an empty string" do
        subject.call(start: "").should be_nil
      end

      it "returns a date" do
        result = subject.call(start: "2013-12-11")
        result.should == Date.new(2013,12,11)
      end
    end

  end
end
