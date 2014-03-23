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
end

class TestReader
  def initialize(opts)
    @parse = opts[:parse] || []
  end
  def parse(data)
    @parse
  end
end

module Stockboy
  describe Job do
    let(:jobs_path) { fixture_path "jobs" }
    let(:provider)  { provider_double }
    let(:reader)    { reader_double }

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
        Job.define("test_job").should be_a Job
      end

      it "yields the defined job" do
        yielded = nil
        job = Job.define("test_job") { |j| yielded = j }
        job.should be_a Job
        job.should be yielded
      end

      it "should read a file from a path" do
        File.should_receive(:read).with("#{jobs_path}/test_job.rb")
        Job.define("test_job")
      end

      it "assigns a registered provider from a symbol" do
        Stockboy::Providers.should_receive(:find)
                           .with(:ftp)
                           .and_return(TestProvider)
        job = Job.define("test_job")
        job.provider.should be_a TestProvider
      end

      it "assigns a registered reader from a symbol" do
        Stockboy::Readers.should_receive(:find)
                         .with(:csv)
                         .and_return(TestReader)
        job = Job.define("test_job")
        job.reader.should be_a TestReader
      end

      it "assigns attributes from a block" do
        job = Job.define("test_job")
        job.attributes.map(&:to).should == [:name, :email, :updated_at]
      end

      it "assigns triggers into their associated array from a block" do
        job = Job.define("test_job")
        job.triggers[:cleanup].size.should == 2
        job.triggers[:cleanup].each { |t| t.should be_a Proc }
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
        job.total_records.should == 2
      end

      it "partitions records by filter" do
        job.reader = double(parse: [{"name"=>"A"},{"name"=>"B"}])
        job.filters = {alpha: proc{ |r| r.name =~ /A/ }}

        job.process
        job.records[:alpha].length.should == 1
      end

      it "keeps unfiltered_records" do
        job.reader = double(parse: [{"name"=>"A"}])
        job.filters = {zeta: proc{ |r| r.name =~ /Z/ }}

        job.process
        job.unfiltered_records.length.should == 1
      end

      it "keeps all_records" do
        job.reader = double(parse: [{"name"=>"A"},{"name"=>"Z"}])
        job.filters = {alpha: proc{ |r| r.name =~ /A/ }}

        job.process
        job.all_records.length.should == 2
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

        counter.matches.should == 0
        2.times { job.process }
        counter.matches.should == 1
      end

      it "has empty partitions" do
        job.filters = {alpha: proc{ |r| r.name =~ /A/ }, beta: proc{ |r| r.name =~ /B/ }}
        job.records.should == {alpha: [], beta: []}
      end
    end

    describe "#record_counts" do
      let(:attribute_map) { AttributeMap.new { name } }

      subject(:job) do
        Job.new(provider: provider, attributes: attribute_map)
      end

      context "before processing" do
        it "should be empty" do
          job.record_counts.should == {}
        end
      end

      it "returns a hash of counts by filtered record partition" do
        job.filters = {
          alpha: proc{ |r| r.name =~ /^A/ },
          zeta:  proc{ |r| r.name =~ /^Z/ }
        }

        job.reader = double(parse: [{"name"=>"Arthur"}, {"name"=>"Abc"}, {"name"=>"Zaphod"}])
        job.process

        job.record_counts.should == {alpha: 2, zeta: 1}
      end
    end

    describe "#processed?" do
      subject(:job) do
        Job.new(provider: provider, reader: reader, attributes: AttributeMap.new)
      end

      it "indicates if the job has been processed" do
        job.processed?.should be_false
        job.process
        job.processed?.should be_true
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
        stats[:count].should == 1
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

    def provider_double(opts={})
      TestProvider.new(opts)
    end

    def reader_double(opts={})
      TestReader.new(opts)
    end
  end
end
