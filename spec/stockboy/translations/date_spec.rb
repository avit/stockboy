require 'spec_helper'
require 'stockboy/translations/date'
require 'active_support/time'

module Stockboy
  describe Translations::Date do

    subject { described_class.new(:start) }

    describe "#call" do
      it "returns nil for an empty string" do
        subject.call(stub(start: "")).should be_nil
      end

      it "returns a date unmodified" do
        result = subject.call stub(start: ::Date.new(2012,12,21))
        result.should == ::Date.new(2012,12,21)
      end

      it "returns a date from a string" do
        result = subject.call stub(start: "2013-12-11")
        result.should == ::Date.new(2013,12,11)
      end

      it "returns a date from a time" do
        result = subject.call stub(start: ::Time.new(2012,12,21,12,21,12))
        result.should == ::Date.new(2012,12,21)
      end

      it "returns a date from a DateTime" do
        result = subject.call stub(start: ::DateTime.new(2012,12,21,12,21,12))
        result.should == ::Date.new(2012,12,21)
      end
    end

  end
end
