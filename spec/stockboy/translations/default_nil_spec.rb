require 'spec_helper'
require 'stockboy/translations/default_nil'

module Stockboy
  describe Translations::DefaultNil do

    subject { described_class.new(:email) }

    describe "#call" do
      it "returns nil for empty string" do
        subject.call(email: "").should == nil
      end

      it "returns nil for nil" do
        subject.call(email: nil).should == nil
      end

      it "returns original value if present" do
        subject.call(email: "a@example.com").should == "a@example.com"
      end

      it "returns original value when zero" do
        subject.call(email: 0).should == 0
      end
    end

  end
end
