require 'spec_helper'
require 'stockboy/reader'

class BookReader < Stockboy::Reader
  def parse(data)
    data
  end
end

class BathroomReader < Stockboy::Reader
end

module Stockboy
  describe Reader do

    describe "#initialize" do
      subject(:reader) { BookReader.new(encoding: 'ISO-8859-1') }
      its(:encoding) { should == 'ISO-8859-1' }
    end

    it "warns of a missing subclass implementation" do
      expect { BathroomReader.new.parse(double) }.to raise_error NoMethodError
    end

  end
end
