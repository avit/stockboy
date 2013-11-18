require 'spec_helper'
require 'stockboy/attribute'

module Stockboy
  describe Attribute do
    it "describes its attrs" do
      attr = Attribute.new :outfield, "infield", [:one, :two]
      attr.inspect.should == %{#<Stockboy::Attribute to=:outfield, from="infield", translators=[:one, :two]>}
    end
  end
end
