require 'spec_helper'
require 'stockboy/translations/us_date.rb'

module Stockboy
  describe Translations::USDate do

    subject { described_class.new(:start) }

    describe "#call" do
      it "returns nil for an empty string" do
        subject.call(start: "").should be_nil
      end

      it "translates US format date strings" do
        result = subject.call(start: "4/6/2013")
        result.should == Date.new(2013,4,6)
      end
    end

  end
end
