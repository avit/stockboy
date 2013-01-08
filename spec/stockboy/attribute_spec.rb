require 'spec_helper'
require 'stockboy/attribute'

module Stockboy
  describe Attribute do
    it "describes its attrs" do
      attr = Attribute.new :infield, :outfield, [:one, :two]
      attr.inspect.should == "#<Stockboy::Attribute to=:infield, from=:outfield, translators=[:one, :two]>"
    end
  end
end
