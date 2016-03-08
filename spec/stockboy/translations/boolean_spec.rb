require 'spec_helper'
require 'stockboy/translations/boolean'

module Stockboy
  describe Translations::Boolean do

    describe "#call" do
      def self.it_should_be(actual, arg)
        it "returns #{actual.inspect} for #{arg[:for].inspect}" do
          result = subject.call arg[:for]
          expect(result).to eq actual
        end
      end

      subject { described_class.new(:bool) }

      it_should_be false, for: {bool: false}
      it_should_be true,  for: {bool:  true}

      it_should_be false, for: {bool:  0 }
      it_should_be false, for: {bool: '0'}
      it_should_be false, for: {bool: 'f'}
      it_should_be false, for: {bool: 'F'}
      it_should_be false, for: {bool: 'false'}
      it_should_be false, for: {bool: 'FALSE'}
      it_should_be false, for: {bool: 'n'}
      it_should_be false, for: {bool: 'N'}
      it_should_be false, for: {bool: 'no'}
      it_should_be false, for: {bool: 'NO'}

      it_should_be true,  for: {bool:  1 }
      it_should_be true,  for: {bool: '1'}
      it_should_be true,  for: {bool: 't'}
      it_should_be true,  for: {bool: 'T'}
      it_should_be true,  for: {bool: 'y'}
      it_should_be true,  for: {bool: 'Y'}
      it_should_be true,  for: {bool: 'yes'}
      it_should_be true,  for: {bool: 'YES'}
      it_should_be true,  for: {bool: 'true'}
      it_should_be true,  for: {bool: 'TRUE'}

      it_should_be nil,   for: {bool: nil}
      it_should_be nil,   for: {bool: '' }
      it_should_be nil,   for: {bool: 'anything else'}
    end

  end
end
