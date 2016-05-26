require 'spec_helper'
require 'stockboy/translations/string'

module Stockboy
  describe Translations::String do

    subject { described_class.new(:name) }

    describe "#call" do
      it "returns '' for nil" do
        result = subject.call name: nil
        expect(result).to eq ""
      end

      it "strips trailing & leading whitespace" do
        result = subject.call name: " Arthur \n"
        expect(result).to eq "Arthur"
      end

      it "casts other types to string" do
        result = subject.call name: 1.0/3
        expect(result).to eq "0.3333333333333333"
      end
    end

  end
end
