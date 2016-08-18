require 'spec_helper'
require 'stockboy/job'

class TestProvider
  attr_reader :data, :errors
  def initialize(opts)
    @data = opts[:data] || ""
    @errors = opts[:errors] || []
  end
  def clear
    @data = nil
  end
  def data_size; @data && @data.size end
  def data_time; @data && Time.now end
  def data?; true end
end

class TestReader
  def initialize(opts)
    @parse = opts[:parse] || []
  end
  def parse(data)
    @parse.respond_to?(:call) ? @parse.call(data) : @parse
  end
end

module Stockboy
  describe Job do
    let(:jobs_path) { fixture_path "jobs" }
    let(:provider)  { provider_double }
    let(:reader)    { reader_double }

    subject(:job) { described_class.new }

    let(:job_template) {
      <<-END.gsub(/^ {6}/,'')
      provider :ftp do
        username 'foo'
        password 'bar'
        host 'ftp.example.com'
      end
      format   :csv
      filter :blank_name do |r|
        false if r.name.blank?
      end
      attributes do
        name from: 'userName'
        email from: 'email'
        updated_at from: 'statusDate', as: [:date]
      end
      on :cleanup do |job|
        job.provider.delete_data
      end
      on :cleanup do |job|
        "log: " << job.all_records.size
      end
      END
    }

    before do
      Stockboy.configuration.template_load_paths = [jobs_path]

      allow(Stockboy::Providers).to receive(:find) { TestProvider }
      allow(Stockboy::Readers).to receive(:find)   { TestReader }
    end

    its(:filters) { should be_a Hash }

    describe "#define" do
      before do
        allow(File).to receive(:read)
            .with("#{jobs_path}/test_job.rb")
            .and_return job_template
      end

      it "returns an instance of Job" do
        expect(Job.define("test_job")).to be_a Job
      end

      it "yields the defined job" do
        yielded = nil
        job = Job.define("test_job") { |j| yielded = j }
        expect(job).to be_a Job
        expect(job).to be yielded
      end

      it "should read a file from a path" do
        expect(File).to receive(:read).with("#{jobs_path}/test_job.rb")
        Job.define("test_job")
      end

      it "assigns a registered provider from a symbol" do
        expect(Stockboy::Providers).to receive(:find)
                                       .with(:ftp)
                                       .and_return(TestProvider)
        job = Job.define("test_job")
        expect(job.provider).to be_a TestProvider
      end

      it "assigns a registered reader from a symbol" do
        expect(Stockboy::Readers).to receive(:find)
                                     .with(:csv)
                                     .and_return(TestReader)
        job = Job.define("test_job")
        expect(job.reader).to be_a TestReader
      end

      it "assigns attributes from a block" do
        job = Job.define("test_job")
        expect(job.attributes.map(&:to)).to eq [:name, :email, :updated_at]
      end

      it "assigns triggers into their associated array from a block" do
        job = Job.define("test_job")
        expect(job.triggers[:cleanup].size).to eq 2
        job.triggers[:cleanup].each { |t| expect(t).to be_a Proc }
      end
    end

    describe "#attributes=" do

      before do
        job.attributes = AttributeMap.new do first_name end
        job.all_records << double
      end

      it "replaces the attribute map" do
        job.attributes = AttributeMap.new do last_name end
        expect(job.attributes.map(&:to)).to eq [:last_name]
      end

      it "resets the job" do
        job.attributes = AttributeMap.new do last_name end
        expect(job.all_records).to be_empty
      end

    end

    describe "#process" do
      let(:attribute_map) { AttributeMap.new { name } }

      subject(:job) do
        Job.new(provider: provider, attributes: attribute_map)
      end

      it "records total received record count" do
        job.reader = reader_double(parse: [{"name"=>"A"},{"name"=>"B"}])

        job.process
        expect(job.total_records).to eq 2
      end

      it "partitions records by filter" do
        job.reader = double(parse: [{"name"=>"A"},{"name"=>"B"}])
        job.filters = {alpha: proc{ |r| r.name =~ /A/ }}

        job.process
        expect(job.records[:alpha].length).to eq 1
      end

      it "keeps unfiltered_records" do
        job.reader = double(parse: [{"name"=>"A"}])
        job.filters = {zeta: proc{ |r| r.name =~ /Z/ }}

        job.process
        expect(job.unfiltered_records.length).to eq 1
      end

      it "keeps all_records" do
        job.reader = double(parse: [{"name"=>"A"},{"name"=>"Z"}])
        job.filters = {alpha: proc{ |r| r.name =~ /A/ }}

        job.process
        expect(job.all_records.length).to eq 2
      end

      it "resets filters between runs" do

        class CountingFilter
          attr_reader :matches
          define_method(:initialize) { |pattern| @pattern, @matches = /A/, 0 }
          define_method(:call)       { |_, output| @matches += 1 if output.name =~ @pattern }
          define_method(:reset)      { @matches = 0 }
        end

        job.reader = double(parse: [{"name"=>"A"},{"name"=>"Z"}])
        job.filters = {alpha: counter = CountingFilter.new(/A/)}

        expect(counter.matches).to eq 0
        2.times { job.process }
        expect(counter.matches).to eq 1
      end

      it "has empty partitions" do
        job.filters = {alpha: proc{ |r| r.name =~ /A/ }, beta: proc{ |r| r.name =~ /B/ }}
        expect(job.records).to eq({alpha: [], beta: []})
      end

      context "with a repeating provider" do
        let(:repeater) {
          ProviderRepeater.new(provider) do |inputs|
            1.upto 3 do |i|
              inputs << provider_double(data: [{"name" => i}])
            end
          end
        }
        let(:noop_reader) { reader_double(parse: ->(data) { data }) }
        let(:job) { Job.new(provider: repeater, reader: noop_reader, attributes: attribute_map) }

        it "it loads all records into a set" do
          job.process
          expect(job.all_records.size).to eq 3
        end

        context "and no data" do
          let(:repeater) {
            ProviderRepeater.new(provider) do |inputs|
            end
          }

          it "gets no records" do
            job.process
            expect(job.all_records.size).to eq 0
          end
        end
      end

    end

    describe "#record_counts" do
      let(:attribute_map) { AttributeMap.new { name } }

      subject(:job) do
        Job.new(provider: provider, attributes: attribute_map)
      end

      context "before processing" do
        it "should be empty" do
          expect(job.record_counts).to eq({})
        end
      end

      it "returns a hash of counts by filtered record partition" do
        job.filters = {
          alpha: proc{ |r| r.name =~ /^A/ },
          zeta:  proc{ |r| r.name =~ /^Z/ }
        }

        job.reader = double(parse: [{"name"=>"Arthur"}, {"name"=>"Abc"}, {"name"=>"Zaphod"}])
        job.process

        expect(job.record_counts).to eq({alpha: 2, zeta: 1})
      end
    end

    describe "#processed?" do
      subject(:job) do
        Job.new(provider: provider, reader: reader, attributes: AttributeMap.new)
      end

      it "indicates if the job has been processed" do
        expect(job.processed?).to be false
        job.process
        expect(job.processed?).to be true
      end
    end

    describe "#trigger" do

      subject(:job) do
        Job.new(
          provider: provider,
          triggers: {
            success: [proc { |j| j.provider.delete_data },
                      proc { |j, stats| stats[:count] = 1 if stats }]
          }
        )
      end

      it "should yield itself to each trigger" do
        expect(job.provider).to receive(:delete_data).once
        job.trigger(:success)
      end

      it "should yield args to each trigger" do
        expect(job.provider).to receive(:delete_data).once
        stats = {}
        job.trigger(:success, stats)
        expect(stats[:count]).to eq 1
      end

    end

    describe "#triggers=" do

      it "replaces existing triggers" do
        job.triggers = {breakfast: double}
        job.triggers = {lunch: double}
        expect(job.triggers.keys).to eq [:lunch]
      end

    end

    describe "#method_missing" do

      subject(:job) { Job.new(triggers: {cleanup: proc{|_|}})}

      it "should call a named trigger" do
        expect(job).to receive(:trigger).with(:cleanup, "trash")
        job.cleanup("trash")
      end

      it "should raise an error for unknown trigger keys" do
        expect { job.wobble }.to raise_error NoMethodError
      end

    end

    describe "#inspect" do
      let(:job) { Job.new(provider: provider_double, reader: reader_double) }
      subject { job.inspect }

      it "is not extraordinarily long" do
        should start_with "#<Stockboy::Job"
        should include "provider=TestProvider"
        should include "reader=TestReader"
        should include "attributes=[]"
        should include "filters=[]"
        should include "record_counts={}"
      end
    end

    def provider_double(opts={})
      TestProvider.new(opts)
    end

    def reader_double(opts={})
      TestReader.new(opts)
    end
  end
end
