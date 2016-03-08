require 'spec_helper'
require 'stockboy/providers'

module Stockboy
  describe Providers do

    let(:provider) { Class.new }

    describe ".register" do
      it "registers a key and class" do
        expect(Providers.register(:snailmail, provider)).to be provider
      end
    end

    describe ".find" do
      it "returns a provider class" do
        Providers.register(:snailmail, provider)
        expect(Providers.find(:snailmail)).to be provider
      end
    end

    describe ".[]" do
      it "returns a provider class" do
        Providers.register(:snailmail, provider)
        expect(Providers[:snailmail]).to be provider
      end
    end

    describe ".all" do
      it "returns all registered providers" do
        Providers.register(:snailmail, provider)
        Providers.register(:slugmail, provider)
        expect(Providers.all).to include(snailmail: provider, slugmail: provider)
      end
    end

  end
end
