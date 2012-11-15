require 'spec_helper'
require 'stockboy/attribute_map'

module Stockboy
  describe AttributeMap do
    subject do
      AttributeMap.new do
        email
        updated_at from: 'statusDate', as: [proc{ |v| Date.parse(v) }]
      end
    end

    it "captures same destination as default" do
      subject[:email].should == AttributeMap::Row.new(:email,"email",[])
    end

    it "sets source from option" do
      subject[:updated_at].from.should == "statusDate"
    end

    it "sets callable translators" do
      subject[:updated_at].translators.first.call("2012-01-01").should == Date.new(2012,1,1)
    end

    it "has attr accessors" do
      subject.email.should be_a AttributeMap::Row
    end

    it "raises error for undefined attrs" do
      expect {subject.foobar}.to raise_error(NoMethodError)
    end

    it "is enumerable" do
      subject.map(&:from).should == ["email", "statusDate"]
      subject.map(&:to).should == [:email, :updated_at]
    end

  end
end
