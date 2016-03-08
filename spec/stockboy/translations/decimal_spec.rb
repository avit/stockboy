require 'spec_helper'
require 'stockboy/translations/decimal'

module Stockboy
  describe Translations::Decimal do

    subject { described_class.new(:total) }

    describe "#call" do
      it "returns nil for an empty string" do
        result = subject.call total: ""
        expect(result).to be nil
      end

      it "returns a decimal" do
        result = subject.call total: "42.42"
        expect(result).to eq 42.42
        expect(result).to be_a BigDecimal
      end
    end

  end
end
