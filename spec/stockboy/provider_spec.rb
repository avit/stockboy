require 'spec_helper'
require 'stockboy/provider'

class ProviderSubclass < Stockboy::Provider
  def validate
    true
  end
  def fetch_data
    @data = "TEST,DATA"
  end
end

module Stockboy
  describe Provider do

    describe "#errors" do
      its(:errors) { should be_empty }
    end

    describe "#logger" do
      its(:logger) { should respond_to :error }
    end

    describe "abstract method" do
      subject { Class.new(Provider).new }

      it "raises error for unimplemented #validate" do
        expect{ subject.send :validate }.to raise_error(NoMethodError)
      end

      it "raises error for unimplemented #fetch_data" do
        expect{ subject.send :fetch_data }.to raise_error(NoMethodError)
      end
    end

    describe "#data" do
      subject(:provider) { ProviderSubclass.new(foo: true) }

      it "fetches data when there is none" do
        expect(provider).to receive(:fetch_data).once.and_call_original
        2.times do
          provider.data.should == "TEST,DATA"
        end
      end

      it "yields data to a block" do
        provider.data do |data|
          data.should == "TEST,DATA"
        end
      end
    end

  end
end
