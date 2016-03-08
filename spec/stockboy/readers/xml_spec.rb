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
          convert_tags_to:      ->(t) { t.snakecase },
          parser:               :nokogiri,
          elements:             ['SomeNested', 'Record']
        )

        expect(reader.options[:strip_namespaces]).to be true
        expect(reader.options[:advanced_typecasting]).to be true
        expect(reader.options[:convert_tags_to]).to be_a Proc
        expect(reader.options[:parser]).to eq :nokogiri
        expect(reader.elements).to eq ['some_nested', 'record']
      end

      it "configures with a block" do
        reader = Readers::XML.new do
          encoding 'UTF-8'
          strip_namespaces true
          advanced_typecasting true
          convert_tags_to ->(t) { t.snakecase }
          parser :nokogiri
          elements ['SomeNested', 'Record']
        end

        expect(reader.options[:strip_namespaces]).to be true
        expect(reader.options[:advanced_typecasting]).to be true
        expect(reader.options[:convert_tags_to]).to be_a Proc
        expect(reader.options[:parser]).to eq :nokogiri
        expect(reader.elements).to eq ['some_nested', 'record']
      end
    end

    describe "#parse" do

      let(:xml_file)    { fixture_path "xml/body.xml" }
      let(:xml_string)  { File.read(xml_file) }
      let(:elements)    { ['MultiNamespacedEntryResponse', 'history', 'case'] }
      let(:output_keys) { ['logTime', 'logType', 'logText'] }
      subject(:reader)  { Readers::XML.new(elements: elements, strip_namespaces: true) }

      shared_examples :parse_data do
        it "returns element hashes" do
          items = reader.parse data
          output_keys.each do |k|
            expect(items[0].keys).to include k
          end
        end

        it "shares key string instances between records" do
          items = reader.parse data
          output_keys.each do |key|
            i = items[0].keys.index(key)
            expect(items[0].keys[i]).to be items[1].keys[i]
          end
        end
      end

      shared_examples :parse_data_with_tag_conversion do
        context "with tag conversion" do
          before            { reader.options[:convert_tags_to] = ->(t) { t.snakecase } }
          let(:output_keys) { ['log_time', 'log_type', 'log_text'] }

          include_examples :parse_data
        end
      end

      context "an XML string" do
        let(:data) { xml_string }

        include_examples :parse_data
        # include_examples :parse_data_with_tag_conversion
      end


      context "a SOAP response" do
        let(:data) { Nori.new(strip_namespaces: true).parse(xml_string) }

        include_examples :parse_data
        include_examples :parse_data_with_tag_conversion
      end

    end
  end
end
