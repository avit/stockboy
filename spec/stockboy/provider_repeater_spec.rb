require 'spec_helper'
require 'stockboy/provider_repeater'

class PaginatedProviderSubclass < Stockboy::Provider
  attr_accessor :page
  def validate; true end
  def fetch_data; @data = "TEST,DATA,#{page}" end
  def data_size; @data && @data.size end
  def data_time; @data && Time.now end
end

module Stockboy
  describe ProviderRepeater do

    let(:provider) { PaginatedProviderSubclass.new }

    describe "#data" do
      let(:repeater) {
        ProviderRepeater.new(provider) do |output, provider|
          1.upto 3 do |i|
            provider.page = i
            output << provider
          end
        end
      }

      it "yields each data set" do
        calls = []
        repeater.data { |data| calls << data.split(",").last }
        expect(calls).to eq ["1", "2", "3"]
      end

      it "raises an error if no block was given" do
        expect{ repeater.data }.to raise_error ArgumentError
      end

    end

    describe "#each" do

      context "without a block" do
        let(:repeater) { ProviderRepeater.new(provider) }

        it "yields the provider once" do
          provider.page = 42
          calls = []
          repeater.each do |nth_provider|
            calls << nth_provider
          end
          expect(calls.map(&:page)).to eq [42]
        end
      end

      context "when it passes a non-provider" do
        let(:repeater) {
          ProviderRepeater.new(provider) do |output, provider|
            output << nil
          end
        }

        it "should raise a helpful error" do
          expect { repeater.each { |provider| } }.to raise_error(
            "expected Provider, got NilClass" )
        end
      end

      context "when it is defined with yield" do
        let(:repeater) {
          ProviderRepeater.new(provider) do |output, provider|
            yield provider
          end
        }

        it "should raise a helpful error" do
          expect { repeater.data { |data| } }.to raise_error(
            "use output << provider instead of yield" )
        end
      end
    end

    describe "#data_size" do
      subject(:repeater) { ProviderRepeater.new(provider) }
      its(:data_size) { should be nil }

      context "after iterating" do
        before { repeater.data do |data| end }
        its(:data_size) { should be > 0 }
      end
    end

    describe "#data_time" do
      subject(:repeater) { ProviderRepeater.new(provider) }
      its(:data_time) { should be nil }

      context "after iterating" do
        before { repeater.data do |data| end }
        its(:data_time) { should be_a Time }
      end
    end

    describe "#data?" do
      subject(:repeater) { ProviderRepeater.new(provider) }
      its(:data?) { should be nil }

      context "after iterating" do
        before { repeater.data do |data| end }
        its(:data?) { should be true }
      end
    end

    describe "#clear" do
      subject(:repeater) { ProviderRepeater.new(provider) }

      it "resets iterations and data" do
        expect(repeater.data_iterations).to eq 0
        repeater.data do |data| end
        expect(repeater.data_iterations).to eq 1
        repeater.clear
        expect(repeater.data_iterations).to eq 0
      end
    end

  end
end
