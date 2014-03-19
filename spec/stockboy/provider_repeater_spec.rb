require 'spec_helper'
require 'stockboy/provider_repeater'

class PaginatedProviderSubclass < Stockboy::Provider
  attr_accessor :page
  def validate
    true
  end
  def fetch_data
    @data = "TEST,DATA,#{page}"
  end
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
        repeater.data { |data| calls << data[-1] }
        calls.should == ["1", "2", "3"]
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
          calls.map(&:page).should == [42]
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

  end
end
