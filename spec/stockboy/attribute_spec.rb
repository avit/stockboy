require 'spec_helper'
require 'stockboy/attribute'

module Stockboy
  describe Attribute do
    it "describes its attrs" do
      attr = Attribute.new :outfield, "infield", [:one, :two], :nil?
      attr.inspect.should == %{#<Stockboy::Attribute to=:outfield, from="infield", translators=[:one, :two], ignore=:nil?>}
    end

    describe :ignore? do
      it "is false by default" do
        attr = Attribute.new :email, "email", []
        attr.ignore?(double email: "").should be false
      end

      it "extracts symbols from a record" do
        attr = Attribute.new :email, "email", [], :blank?
        attr.ignore?(double email: "").should be true
        attr.ignore?(double email: "@").should be false
      end

      it "is true with a truthy value" do
        attr = Attribute.new :email, "email", [], 1
        attr.ignore?(double email: "").should be true
      end

      it "yields records to a proc" do
        attr = Attribute.new :email, "email", [], ->(r) { not r.email.include? "@" }
        attr.ignore?(double email: "").should be true
        attr.ignore?(double email: "@").should be false
      end

    end
  end
end
