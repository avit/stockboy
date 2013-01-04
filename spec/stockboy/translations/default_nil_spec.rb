require 'spec_helper'
require 'stockboy/translations/default_nil'

module Stockboy
  describe Translations::DefaultNil do

    subject { described_class.new(:email) }

    describe "#call" do
      it "returns nil for empty string" do
        result = subject.call stub(email: "")
        result.should == nil
      end

      it "returns nil for nil" do
        result = subject.call stub(email: nil)
        result.should == nil
      end

      it "returns original value if present" do
        result = subject.call stub(email: "a@example.com")
        result.should == "a@example.com"
      end

      it "returns original value when zero" do
        result = subject.call stub(email: 0)
        result.should == 0
      end
    end

  end
end
