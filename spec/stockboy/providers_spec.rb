require 'spec_helper'
require 'stockboy/providers'

module Stockboy
  describe Providers do

    let(:provider) { Class.new }

    describe ".register" do
      it "registers a key and class" do
        Providers.register(:snailmail, provider).should be provider
      end
    end

    describe ".find" do
      it "returns a provider class" do
        Providers.register(:snailmail, provider)
        Providers.find(:snailmail).should be provider
      end
    end

    describe ".[]" do
      it "returns a provider class" do
        Providers.register(:snailmail, provider)
        Providers[:snailmail].should be provider
      end
    end

    describe ".all" do
      it "returns all registered providers" do
        Providers.register(:snailmail, provider)
        Providers.register(:slugmail, provider)
        Providers.all.should include(snailmail: provider, slugmail: provider)
      end
    end

  end
end
