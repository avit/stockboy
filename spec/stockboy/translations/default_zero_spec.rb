require 'spec_helper'
require 'stockboy/translations/default_zero'

module Stockboy
  describe Translations::DefaultZero do

    subject { described_class.new(:count) }

    describe "#call" do
      it "returns zero for nil" do
        result = subject.call count: nil
        expect(result).to eq 0
      end

      it "returns zero for empty string" do
        result = subject.call count: ""
        expect(result).to eq 0
      end

      it "returns original value if present" do
        result = subject.call count: 42
        expect(result).to eq 42
      end

      it "returns original value when zero" do
        result = subject.call count: 0
        expect(result).to eq 0
      end
    end

  end
end
