require 'spec_helper'
require 'stockboy/filter'

class FishFilter < Stockboy::Filter
  def filter(raw, translated)
    return true if raw.species =~ /ichtus/
    return true if translated.species =~ /fish/
    return nil
  end
end

module Stockboy
  describe Filter do

    describe "#call" do
      let(:empty_values) { double.as_null_object }
      subject(:filter) { FishFilter.new }

      context "matching raw value" do
        it "returns true for match" do
          filter.call(double(species:"babylichtus"), empty_values).should be_true
        end

        it "returns false for no match" do
          filter.call(double(species:"triceratops"), empty_values).should be_false
        end
      end

      context "matching translated value" do
        it "returns true for match" do
          filter.call(empty_values, double(species:"babelfish")).should be_true
        end

        it "returns false for no match" do
          filter.call(empty_values, double(species:"rhinoceros")).should be_false
        end
      end
    end

  end
end
