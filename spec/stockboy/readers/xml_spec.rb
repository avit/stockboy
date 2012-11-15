require 'spec_helper'
require 'stockboy/readers/xml'

module Stockboy
  describe Readers::XML do
    it "initializes hash options" do
      subject = Readers::XML.new
    end
  end
end
