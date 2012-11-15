require 'spec_helper'
require 'stockboy/translations/default_empty_string'

module Stockboy
  describe Translations::DefaultEmptyString do

    subject { described_class.new(:comment) }

    describe "#call" do
      it "returns empty string for nil" do
        subject.call(comment: nil).should == ""
      end

      it "returns empty string for an empty string" do
        subject.call(comment: "").should == ""
      end

      it "returns original value if present" do
        subject.call(comment: "asdf").should == "asdf"
      end

      it "returns original value when zero" do
        subject.call(comment: 0).should == 0
      end
    end

  end
end
