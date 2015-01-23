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
        map[:email].should == row
      end
    end

    it "sets same destination as default" do
      subject[:email].should == Attribute.new(:email, "email", [])
    end

    it "sets source from string to string" do
      map = AttributeMap.new { updated_at from: "statusDate" }
      map[:updated_at].from.should == "statusDate"
    end

    it "sets source from symbol to string" do
      map = AttributeMap.new { updated_at from: :statusDate }
      map[:updated_at].from.should == "statusDate"
    end

    it "sets source from number to number" do
      map = AttributeMap.new { email from: 12 }
      map[:email].from.should == 12
    end

    it "sets callable translators" do
      subject[:updated_at].translators.first.call("2012-01-01").should == Date.new(2012,1,1)
    end

    it "sets ignore conditions" do
      expect( subject[:score].ignore_condition ).to be :zero?
    end

    it "has attr accessors" do
      subject.email.should be_a Attribute
    end

    it "raises error for undefined attrs" do
      expect {subject.foobar}.to raise_error(NoMethodError)
    end

    it "is enumerable" do
      subject.map(&:from).should == ["email", "score", "statusDate"]
      subject.map(&:to).should == [:email, :score, :updated_at]
    end

    describe "#insert" do
      subject(:map) { AttributeMap.new }

      it "sets options from hash" do
        upcase = ->(r) { r.upcase }
        map.insert :test, from: "Test", as: upcase
        map[:test].should == Attribute.new(:test, "Test", [upcase])
      end
    end

  end
end
