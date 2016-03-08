require 'spec_helper'
require 'stockboy/translations/default_empty_string'

module Stockboy
  describe Translations::DefaultEmptyString do

    subject { described_class.new(:comment) }

    describe "#call" do
      it "returns empty string for nil" do
        result = subject.call comment: nil
        expect(result).to eq ""
      end

      it "returns empty string for an empty string" do
        result = subject.call comment: ""
        expect(result).to eq ""
      end

      it "returns original value if present" do
        result = subject.call comment: "asdf"
        expect(result).to eq "asdf"
      end

      it "returns original value when zero" do
        result = subject.call comment: 0
        expect(result).to eq 0
      end
    end

  end
end
