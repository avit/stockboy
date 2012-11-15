require 'spec_helper'
require 'stockboy/readers'

module Stockboy
  describe Readers do

    let(:reader_class) { Class.new }

    describe ".register" do
      it "registers a key for a reader class" do
        Readers.register(:markup, reader_class).should == reader_class
      end
    end

    describe ".find" do
      it "returns a reader class" do
        Readers.register(:markup, reader_class)
        Readers.find(:markup).should == reader_class
      end
    end

    describe ".[]" do
      it "returns a reader class" do
        Readers.register(:markup, reader_class)
        Readers[:markup].should == reader_class
      end
    end

  end
end
