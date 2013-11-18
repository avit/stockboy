require 'spec_helper'
require 'stockboy/translations/string'

module Stockboy
  describe Translations::String do

    subject { described_class.new(:name) }

    describe "#call" do
      it "returns '' for nil" do
        result = subject.call name: nil
        result.should == ""
      end

      it "strips trailing & leading whitespace" do
        result = subject.call name: " Arthur \n"
        result.should == "Arthur"
      end
    end

  end
end
