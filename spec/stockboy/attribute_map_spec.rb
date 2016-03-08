require 'spec_helper'
require 'stockboy/attribute_map'

module Stockboy
  describe AttributeMap do

    subject do
      AttributeMap.new do
        email
        score      ignore: :zero?
        updated_at from: 'statusDate', as: [proc{ |v| Date.parse(v) }]
      end
    end

    describe ".new" do
      let(:row) { Attribute.new(:email, "email", []) }

      it "initializes from hash attribute" do
        map = AttributeMap.new(:email => row)
        expect(map[:email]).to eq row
      end
    end

    it "sets same destination as default" do
      expect(subject[:email]).to eq Attribute.new(:email, "email", [])
    end

    it "sets source from string to string" do
      map = AttributeMap.new { updated_at from: "statusDate" }
      expect(map[:updated_at].from).to eq "statusDate"
    end

    it "sets source from symbol to string" do
      map = AttributeMap.new { updated_at from: :statusDate }
      expect(map[:updated_at].from).to eq "statusDate"
    end

    it "sets source from number to number" do
      map = AttributeMap.new { email from: 12 }
      expect(map[:email].from).to eq 12
    end

    it "sets callable translators" do
      expect(subject[:updated_at].translators.first.call("2012-01-01")).to eq Date.new(2012,1,1)
    end

    it "sets ignore conditions" do
      expect( subject[:score].ignore_condition ).to be :zero?
    end

    it "has attr accessors" do
      expect(subject.email).to be_a Attribute
    end

    it "raises error for undefined attrs" do
      expect {subject.foobar}.to raise_error(NoMethodError)
    end

    it "is enumerable" do
      expect(subject.map(&:from)).to eq ["email", "score", "statusDate"]
      expect(subject.map(&:to)).to eq [:email, :score, :updated_at]
    end

    describe "#insert" do
      subject(:map) { AttributeMap.new }

      it "sets options from hash" do
        upcase = ->(r) { r.upcase }
        map.insert :test, from: "Test", as: upcase
        expect(map[:test]).to eq Attribute.new(:test, "Test", [upcase])
      end
    end

  end
end
