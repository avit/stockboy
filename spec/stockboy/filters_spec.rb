require 'spec_helper'
require 'stockboy/filters'

module Stockboy
  describe Filters do

    let(:filter) { stub("filter") }

    describe ".register" do
      it "registers a key and class" do
        Filters.register(:invalid, filter).should === filter
      end
    end

    describe ".find" do
      it "returns a filter class" do
        Filters.register(:invalid, filter)
        Filters.find(:invalid).should === filter
      end
    end

    describe ".[]" do
      it "returns a filter class" do
        Filters.register(:invalid, filter)
        Filters[:invalid].should === filter
      end
    end

    describe ".all" do
      it "returns all registered filters" do
        Filters.register(:invalid, filter)
        Filters.register(:semivalid, filter)
        Filters.all.should include(invalid: filter, semivalid: filter)
      end
    end

  end
end
