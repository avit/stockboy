require 'spec_helper'
require 'stockboy/filter_chain'

module Stockboy
  describe FilterChain do

    let(:filter1) { double("Filter") }
    let(:filter2) { double("Filter", reset: true) }

    it "initializes keys and values from a hash" do
      chain = FilterChain.new(no_angels: filter1, no_daleks: filter2)
      expect(chain.keys).to eq [:no_angels, :no_daleks]
      expect(chain.values).to eq [filter1, filter2]
    end

    describe "#reset" do
      let(:chain) { FilterChain.new(no_angels: filter1, no_daleks: filter2) }

      it "calls reset on all members" do
        expect(filter2).to receive(:reset)
        chain.reset
      end

      it "returns a hash of filter keys to empty arrays" do
        empty_records = chain.reset
        expect(empty_records).to eq({no_angels: [], no_daleks: []})
      end
    end

    describe "#prepend" do
      it "adds filters to the front of the chain" do
        chain = FilterChain.new(filter1: double)
        chain.prepend(filter0: double)
        expect(chain.keys).to eq [:filter0, :filter1]
      end
    end

  end
end

