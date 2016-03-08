require 'spec_helper'
require 'stockboy/filters'

module Stockboy
  describe Filters do

    let(:filter) { double("filter") }

    describe ".register" do
      it "registers a key and class" do
        expect(Filters.register(:invalid, filter)).to be === filter
      end
    end

    describe ".find" do
      it "returns a filter class" do
        Filters.register(:invalid, filter)
        expect(Filters.find(:invalid)).to be === filter
      end
    end

    describe ".[]" do
      it "returns a filter class" do
        Filters.register(:invalid, filter)
        expect(Filters[:invalid]).to be === filter
      end
    end

    describe ".all" do
      it "returns all registered filters" do
        Filters.register(:invalid, filter)
        Filters.register(:semivalid, filter)
        expect(Filters.all).to include(invalid: filter, semivalid: filter)
      end
    end

  end
end
