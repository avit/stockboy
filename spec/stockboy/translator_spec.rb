require 'spec_helper'
require 'stockboy/translator'

module Stockboy
  describe Translator do

    describe "template methods" do
      subject { Class.new(Stockboy::Translator).new("_") }
      it "raise error for unimplemented #translate" do
        expect { subject.send :translate, "_" }.to raise_error(NoMethodError)
      end
    end

  end
end
