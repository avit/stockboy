require 'spec_helper'
require 'stockboy/translator'

MyTranslator = Class.new(Stockboy::Translator)

module Stockboy
  describe Translator do

    describe "template methods" do
      subject { Class.new(Stockboy::Translator).new("_") }
      it "raise error for unimplemented #translate" do
        expect { subject.send :translate, "_" }.to raise_error(NoMethodError)
      end
    end

    describe "#inspect" do
      it "names its field key" do
        str = Class.new(Stockboy::Translator).new(:date).inspect
        expect(str).to eq "#<Stockboy::Translator (date)>"

        str = MyTranslator.new(:date).inspect
        expect(str).to eq "#<MyTranslator (date)>"
      end
    end

  end
end
