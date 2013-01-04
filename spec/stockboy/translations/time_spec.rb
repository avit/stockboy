require 'spec_helper'
require 'stockboy/translations/time'

module Stockboy
  describe Translations::Time do

    subject { described_class.new(:start) }

    describe "#call" do
      it "returns nil for an empty string" do
        result = subject.call stub(start: "")
        result.should be_nil
      end

      it "returns a time" do
        result = subject.call stub(start: "2013-12-11 10:09:08")
        result.should == Time.utc(2013,12,11,10,9,8)
      end

      it "respects timezone" do
        result = subject.call stub(start: "2013-12-11 10:09:08 -0800")
        result.should == Time.utc(2013,12,11,18,9,8)
      end
    end

  end
end
