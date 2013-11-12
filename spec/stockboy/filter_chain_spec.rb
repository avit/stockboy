require 'spec_helper'
require 'stockboy/filter_chain'

module Stockboy
  describe FilterChain do

    let(:filter1) { double("Filter") }
    let(:filter2) { double("Filter", reset: true) }

    it "initializes keys and values from a hash" do
      chain = FilterChain.new(no_angels: filter1, no_daleks: filter2)
      chain.keys.should == [:no_angels, :no_daleks]
      chain.values.should == [filter1, filter2]
    end

    describe "#reset" do
      let(:chain) { FilterChain.new(no_angels: filter1, no_daleks: filter2) }

      it "calls reset on all members" do
        filter2.should_receive(:reset)
        chain.reset
      end

      it "returns a hash of filter keys to empty arrays" do
        empty_records = chain.reset
        empty_records.should == {no_angels: [], no_daleks: []}
      end
    end

    describe "#prepend" do
      it "adds filters to the front of the chain" do
        chain = FilterChain.new(filter1: double)
        chain.prepend(filter0: double)
        chain.keys.should == [:filter0, :filter1]
      end
    end

  end
end

