require 'spec_helper'
require 'stockboy/translations/default_zero'

module Stockboy
  describe Translations::DefaultZero do

    subject { described_class.new(:count) }

    describe "#call" do
      it "returns zero for nil" do
        subject.call(count: nil).should == 0
      end

      it "returns zero for empty string" do
        subject.call(count: "").should == 0
      end

      it "returns original value if present" do
        subject.call(count: 42).should == 42
      end

      it "returns original value when zero" do
        subject.call(count: 0).should == 0
      end
    end

  end
end
