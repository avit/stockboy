require 'spec_helper'
require 'stockboy/attribute'

module Stockboy
  describe Attribute do
    it "describes its attrs" do
      attr = Attribute.new :outfield, "infield", [:one, :two], :nil?
      attr.inspect.should == %{#<Stockboy::Attribute to=:outfield, from="infield", translators=[:one, :two], ignore=:nil?>}
    end
  end
end
