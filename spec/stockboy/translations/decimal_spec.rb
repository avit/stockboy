require 'spec_helper'
require 'stockboy/translations/decimal'

module Stockboy
  describe Translations::Decimal do

    subject { described_class.new(:total) }

    describe "#call" do
      it "returns nil for an empty string" do
        result = subject.call total: ""
        result.should be_nil
      end

      it "returns a decimal" do
        result = subject.call total: "42.42"
        result.should == 42.42
        result.should be_a BigDecimal
      end
    end

  end
end
