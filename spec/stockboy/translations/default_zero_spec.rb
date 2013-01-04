require 'spec_helper'
require 'stockboy/translations/default_zero'

module Stockboy
  describe Translations::DefaultZero do

    subject { described_class.new(:count) }

    describe "#call" do
      it "returns zero for nil" do
        result = subject.call stub(count: nil)
        result.should == 0
      end

      it "returns zero for empty string" do
        result = subject.call stub(count: "")
        result.should == 0
      end

      it "returns original value if present" do
        result = subject.call stub(count: 42)
        result.should == 42
      end

      it "returns original value when zero" do
        result = subject.call stub(count: 0)
        result.should == 0
      end
    end

  end
end
