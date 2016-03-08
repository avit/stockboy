require 'spec_helper'
require 'stockboy/translations/date'
require 'active_support/time'

module Stockboy
  describe Translations::Date do

    subject { described_class.new(:start) }

    describe "#call" do
      it "returns nil for an empty string" do
        result = subject.call start: ""
        expect(result).to be nil
      end

      it "returns a date unmodified" do
        result = subject.call start: ::Date.new(2012,12,21)
        expect(result).to eq ::Date.new(2012,12,21)
      end

      it "returns a date from a string" do
        result = subject.call start: '2013-12-11'
        expect(result).to eq ::Date.new(2013,12,11)
      end

      it "returns a date from a time" do
        result = subject.call start: ::Time.new(2012,12,21,12,21,12)
        expect(result).to eq ::Date.new(2012,12,21)
      end

      it "returns a date from a DateTime" do
        result = subject.call start: ::DateTime.new(2012,12,21,12,21,12)
        expect(result).to eq ::Date.new(2012,12,21)
      end
    end

  end
end
