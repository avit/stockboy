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
    end

  end
end
