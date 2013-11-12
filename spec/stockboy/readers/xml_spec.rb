require 'spec_helper'
require 'stockboy/readers/xml'

module Stockboy
  describe Readers::XML do
    subject(:reader) { Stockboy::Readers::XML.new }

    describe "initialize" do
      it "initializes hash options" do
        reader = Readers::XML.new(
          strip_namespaces:     true,
          advanced_typecasting: true,
          convert_tags_to:      ->(t) { t.snake_case.to_sym },
          parser:               :nokogiri,
          elements: [:nested, :record]
        )

        reader.options[:strip_namespaces].should be_true
        reader.options[:advanced_typecasting].should be_true
        reader.options[:convert_tags_to].should be_a Proc
        reader.options[:parser].should == :nokogiri
        reader.elements.should == [:nested, :record]
      end

      it "configures with a block" do
        reader = Readers::XML.new do
          encoding 'UTF-8'
          strip_namespaces true
          advanced_typecasting true
          convert_tags_to ->(t) { t.snake_case.to_sym }
          parser :nokogiri
          elements [:nested, :record]
        end

        reader.options[:strip_namespaces].should be_true
        reader.options[:advanced_typecasting].should be_true
        reader.options[:convert_tags_to].should be_a Proc
        reader.options[:parser].should == :nokogiri
        reader.elements.should == [:nested, :record]
      end
    end

    describe "#parse" do

      subject(:reader) { Stockboy::Readers::XML.new(elements: ['ul', 'li']) }
      let(:xml_fixture) { "<ul><li><b>one</b></li><li><b>two</b></li></ul>" }

      it "parses an xml string" do
        items = reader.parse xml_fixture

        items.should == [{'b' => 'one'}, {'b' => 'two'}]
      end

      it "parses a SOAP response" do
        response = double(to_hash: {'ul'=>{'li'=>[{'b'=>'one'}, {'b'=>'two'}]}})
        items = reader.parse response

        items.should == [{'b' => 'one'}, {'b' => 'two'}]
      end

    end
  end
end
