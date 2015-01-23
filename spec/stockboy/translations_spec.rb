require 'spec_helper'
require 'stockboy/translations'

module Stockboy
  describe Translations do

    subject { Translations }

    describe ".register" do
      it "accepts a class with method #call" do
        translation_class = Class
        allow(translation_class).to receive(:call)
        Translations.register(:from_class, translation_class)
      end

      it "accepts a callable method" do
        translation_method = "Mr. ".public_method(:<<)
        Translations.register :from_method, translation_method
      end

      it "accepts a lambda" do
        translation_lambda = ->(i){ i.some_method }
        Translations.register :from_lambda, translation_lambda
      end

      it "rejects non-callable objects" do
        expect { Translations.register(:wrong, Object) }.to raise_error
      end
    end

    describe ".translate" do
      it "translates a string" do
        Translations.register :personalize, "Dear Mr. ".public_method(:<<)

        Translations.translate(:personalize, "Fun").should == "Dear Mr. Fun"
      end

      it "translates from a proc" do
        myproc = proc { |context| "Dear Mr. #{context[:first_name]}" }
        Translations.translate(myproc, {first_name: "Fun"}).should == "Dear Mr. Fun"
      end
    end

    describe ".translator_for" do
      it "returns a translator for a registered proc" do
        Translations.register :test, ->(i){ i.message.upcase }
        tr = Translations.translator_for(:message, :test)
        tr.call(double message: "no!").should == "NO!"
      end

      it "returns a translator for a registered class" do
        Translations.register :test, Translations::Integer
        tr = Translations.translator_for :id, :test
        tr.call(double id: "42").should == 42
      end

      it "returns a translator for a registered instance" do
        Translations.register :test, Translations::Integer.new(:id)
        tr = Translations.translator_for :anything, :test
        tr.call(double id: "42").should == 42
      end

      it "returns a no-op for unrecognized translators" do
        tr = Translations.translator_for :id, :fail
        tr.call(double id: "42").should == "42"
      end
    end

    describe ".find" do
      it "returns a callable translator" do
        callable = ->(i){ i.message.upcase }
        Translations.register :shout, callable

        Translations.find(:shout).should be callable
        Translations[:shout].should be callable
      end
    end

  end
end
