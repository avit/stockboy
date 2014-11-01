require 'spec_helper'
require 'stockboy/candidate_record'

module Stockboy
  describe CandidateRecord do

    let(:hash_attrs) do
      {'id' => '1',
       'full_name' => 'Arthur Dent',
       'email' => 'adent@example.com',
       'birthday' => '1980-01-01'}
    end

    describe "initialize" do
      let(:map) { AttributeMap.new { id; email } }

      it "takes a hash and attributes map" do
        record = CandidateRecord.new(hash_attrs, map)
      end
    end

    describe "#to_hash" do
      it "remaps attributes" do
        map = AttributeMap.new { name from: 'full_name' }
        subject = CandidateRecord.new(hash_attrs, map).to_hash
        subject.should == { :name => 'Arthur Dent' }
      end

      it "converts String subclasses to clean strings" do
        stub_const 'Nori::StringWithAttributes', Class.new(String)
        map = AttributeMap.new { full_name }
        hash_attrs['full_name'] = Nori::StringWithAttributes.new('Arthur')
        subject = CandidateRecord.new(hash_attrs, map).to_hash
        subject[:full_name].class.should == String
      end
    end

    describe "#raw_hash" do
      it "remaps attributes" do
        map = AttributeMap.new { name from: 'full_name' }
        subject = CandidateRecord.new(hash_attrs, map).raw_hash
        subject.should == { :name => 'Arthur Dent' }
      end

      it "does not translate attributes" do
        map = AttributeMap.new { birthday as: ->(r) { Date.parse(r.birthday) } }
        subject = CandidateRecord.new(hash_attrs, map).raw_hash
        subject.should == { :birthday => "1980-01-01" }
      end
    end

    describe "attribute translation" do
      subject(:hash) { CandidateRecord.new(hash_attrs, map).to_hash }

      context "from lambda" do
        let(:map) { AttributeMap.new{ birthday as: ->(r){ Date.parse(r.birthday) } } }
        it { should == {birthday: Date.new(1980,1,1)} }
      end

      context "from symbol lookup" do
        before    { Stockboy::Translations.register :date, ->(r){ Date.parse(r.birthday) } }
        let(:map) { AttributeMap.new{ birthday :as => :date } }
        it { should == {birthday: Date.new(1980,1,1)} }
      end

      context "chaining" do
        let(:map) { AttributeMap.new{ id as: [->(r){r.id.next}, ->(r){r.id.next}] } }
        it { should == {id: '3'} }
      end

      context "with exception" do
        let(:map) { AttributeMap.new{ id as: [->(r){r.id.to_i}, ->(r){r.id / 0}] } }
        it { should == {id: nil} }
      end

      context "dynamic without an input field" do
        let(:map) { AttributeMap.new{ generated as: [->(r){ "from lambda" }] } }
        it { should == {generated: "from lambda"} }
      end
    end

    describe "#to_model" do
      it "should instantiate a new model" do
        model = Class.new(OpenStruct)
        expect(model).to receive(:new).with({id: '1', name: 'Arthur Dent'})
        map = AttributeMap.new { id; name from: 'full_name' }
        subject = CandidateRecord.new(hash_attrs, map)

        subject.to_model(model)
      end
    end

    describe "#input" do
      describe "[]" do
        it "fetches raw values for raw input keys" do
          map = AttributeMap.new { name from: 'full_name' }
          subject = CandidateRecord.new(hash_attrs, map)
          subject.input['full_name'].should == 'Arthur Dent'
        end
      end

      it "accesses fields by mapped name before translation" do
        map = AttributeMap.new { name from: 'full_name', as: ->(r){ r.name.upcase } }
        subject = CandidateRecord.new(hash_attrs, map)
        subject.input.name.should == 'Arthur Dent'
      end
    end

    describe "#output" do
      describe "[]" do
        it "fetches translated values for raw input keys" do
          map = AttributeMap.new { name from: 'full_name' }
          subject = CandidateRecord.new(hash_attrs, map)
          subject.output.name.should == 'Arthur Dent'
        end
      end
    end

    describe "#partition" do
      subject do
        CandidateRecord.new({'name' =>'Arthur'}, AttributeMap.new { name })
      end

      it "returns first matched filter key" do
        key = subject.partition(zeta:  proc{ |raw| raw.name =~ /Z/ },
                                alpha: proc{ |raw| raw.name =~ /A/ })
        key.should == :alpha
      end

      it "returns a match for translated block argument" do
        map = AttributeMap.new { name as: ->(r){ r.name.downcase } }
        subject = CandidateRecord.new({'name' =>'Arthur'}, map)

        key = subject.partition(down: proc{ |raw,out| out.name[0] == "a" })
        key.should == :down
      end

      it "returns nil when raw field is unmatched" do
        key = subject.partition({beta: proc{ |raw| raw.name =~ /B/ }})
        key.should be nil
      end

      it "returns nil when translated field is unmatched" do
        key = subject.partition({beta: proc{ |raw,out| out.name =~ /B/ }})
        key.should be nil
      end
    end

  end
end
