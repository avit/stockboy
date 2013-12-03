require 'spec_helper'
require 'stockboy/translations/default_false'

module Stockboy
  describe Translations::DefaultFalse do

    describe "#call" do
      def self.it_should_be(actual, arg)
        it "returns #{actual.inspect} for #{arg[:for].inspect}" do
          result = subject.call arg[:for]
          result.should eq actual
        end
      end

      subject { described_class.new(:bool) }

      it_should_be false, for: {bool: false}
      it_should_be true,  for: {bool:  true}

      it_should_be false, for: {bool: nil}
      it_should_be '',    for: {bool: '' }
    end

  end
end
