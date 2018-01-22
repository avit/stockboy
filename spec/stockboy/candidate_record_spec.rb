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

    describe "#to_hash" do
      it "remaps attributes" do
        map = AttributeMap.new { name from: 'full_name' }
        subject = CandidateRecord.new(hash_attrs, map).to_hash
        expect(subject).to eq({ :name => 'Arthur Dent' })
      end

      it "converts String subclasses to clean strings" do
        stub_const 'Nori::StringWithAttributes', Class.new(String)
        map = AttributeMap.new { full_name }
        hash_attrs['full_name'] = Nori::StringWithAttributes.new('Arthur')
        subject = CandidateRecord.new(hash_attrs, map).to_hash
        expect(subject[:full_name].class).to eq String
      end

      it "omits ignored attributes" do
        invalid_email = ->(r) { r.email.include?('example.com') }
        map = AttributeMap.new { id ; email ignore: invalid_email }
        subject = CandidateRecord.new(hash_attrs, map).to_hash
        expect(subject).to eq({ :id => '1' })
      end
    end

    describe "#raw_hash" do
      it "remaps attributes" do
        map = AttributeMap.new { name from: 'full_name' }
        subject = CandidateRecord.new(hash_attrs, map).raw_hash
        expect(subject).to eq({ :name => 'Arthur Dent' })
      end

      it "does not translate attributes" do
        map = AttributeMap.new { birthday as: ->(r) { Date.parse(r.birthday) } }
        subject = CandidateRecord.new(hash_attrs, map).raw_hash
        expect(subject).to eq({ :birthday => "1980-01-01" })
      end
    end

    describe "attribute translation" do
      let (:record) { CandidateRecord.new(hash_attrs, map) }
      subject(:hash) { record.to_hash }

      context "from lambda" do
        let(:map) { AttributeMap.new{ birthday as: ->(r){ Date.parse(r.birthday) } } }
        it { should eq({birthday: Date.new(1980,1,1)}) }
      end

      context "from symbol lookup" do
        before    { Stockboy::Translations.register :date, ->(r){ Date.parse(r.birthday) } }
        let(:map) { AttributeMap.new{ birthday :as => :date } }
        it { should eq({birthday: Date.new(1980,1,1)}) }
      end

      context "chaining" do
        let(:map) { AttributeMap.new{ id as: [->(r){r.id.next}, ->(r){r.id.next}] } }
        it { should eq({id: '3'}) }
      end

      context "with exception" do
        let(:map) { AttributeMap.new{ id as: [->(r){r.id.to_i}, ->(r){r.id / 0}] } }
        let(:last_line) { __LINE__ - 1 }

        it { should eq({id: nil}) }

        context "while debugging" do
          around do |example|
            handler = Stockboy.configuration.translation_error_handler
            example.run
            Stockboy.configuration.translation_error_handler = handler
          end

          it "raises the error" do
            captured = nil
            Stockboy.configuration.translation_error_handler = ->(error) do
              captured = error
              raise error
            end

            expect { hash }.to raise_error(Stockboy::TranslationError)
            expect(captured.message).to eq "Attribute [id] caused divided by 0"
            expect(captured.key).to eq :id
            expect(captured.record).to be record
            expect(captured.backtrace[0]).to start_with "#{__FILE__}:#{last_line}:"
          end
        end
      end

      context "dynamic without an input field" do
        let(:map) { AttributeMap.new{ generated as: [->(r){ "from lambda" }] } }
        it { should eq({generated: "from lambda"}) }
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
          expect(subject.input['full_name']).to eq 'Arthur Dent'
        end
      end

      it "accesses fields by mapped name before translation" do
        map = AttributeMap.new { name from: 'full_name', as: ->(r){ r.name.upcase } }
        subject = CandidateRecord.new(hash_attrs, map)
        expect(subject.input.name).to eq 'Arthur Dent'
      end
    end

    describe "#output" do
      describe "[]" do
        it "fetches translated values for raw input keys" do
          map = AttributeMap.new { name from: 'full_name' }
          subject = CandidateRecord.new(hash_attrs, map)
          expect(subject.output.name).to eq 'Arthur Dent'
        end

        it "returns translated values for ignored keys" do
          map = AttributeMap.new { email ignore: ->(r){ r.email.include?("example.com") } }
          subject = CandidateRecord.new(hash_attrs, map)
          expect(subject.output.email).to eq "adent@example.com"
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
        expect(key).to eq :alpha
      end

      it "returns a match for translated block argument" do
        map = AttributeMap.new { name as: ->(r){ r.name.downcase } }
        subject = CandidateRecord.new({'name' =>'Arthur'}, map)

        key = subject.partition(down: proc{ |raw,out| out.name[0] == "a" })
        expect(key).to eq :down
      end

      it "returns nil when raw field is unmatched" do
        key = subject.partition({beta: proc{ |raw| raw.name =~ /B/ }})
        expect(key).to be nil
      end

      it "returns nil when translated field is unmatched" do
        key = subject.partition({beta: proc{ |raw,out| out.name =~ /B/ }})
        expect(key).to be nil
      end
    end

    describe "==" do
      let (:map1)     { AttributeMap.new {id;full_name;email;birthday} }
      let (:map2)     { AttributeMap.new {id;full_name;email;birthday} }
      let (:record1)  { CandidateRecord.new(hash_attrs, map1) }
      let (:record2)  { CandidateRecord.new(hash_attrs, map2) }

      it "is true with two records with the same attributes" do
        expect(record1 == record2).to be true
        expect(record1.eql? record2).to be true
      end
    end

    describe "hash" do
      let (:map1)     { AttributeMap.new {id;full_name;email;birthday} }
      let (:map2)     { AttributeMap.new {id;full_name;email;birthday} }
      let (:record1)  { CandidateRecord.new(hash_attrs, map1) }
      let (:record2)  { CandidateRecord.new(hash_attrs, map2) }

      it "generates a consistent md5 hash of the record" do
        expect(record1.hash).to eq(record2.hash)
      end

      context "with attributes in different order" do
        let (:map2)   { AttributeMap.new {email;birthday;id;full_name} }

        it "should have different hash" do
          expect(record1.hash).to_not eq(record2.hash)
        end
      end

      context "with an ignored attribute" do
        let (:map2)   { AttributeMap.new {id ignore: true;full_name;email;birthday} }

        it "should have different hash" do
          expect(record1.hash).to_not eq(record2.hash)
        end
      end

      context "with a translated attribute" do
        let (:map2)   { AttributeMap.new {id;full_name as: ->(r){ r.full_name.upcase };email;birthday} }

        it "should have different hash" do
          expect(record1.hash).to_not eq(record2.hash)
        end
      end

      context "with an attributes name changed" do
        let (:map2)   { AttributeMap.new {id;full_name;contact from: "email" ;birthday} }

        it "should have different hash" do
          expect(record1.hash).to_not eq(record2.hash)
        end
      end
    end
  end
end
