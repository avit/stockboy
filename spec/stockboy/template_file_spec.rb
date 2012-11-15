require 'spec_helper'
require 'stockboy/template_file'

module Stockboy
  describe TemplateFile do

    let(:template_path) { File.expand_path("../../fixtures/jobs", __FILE__) }

    before do
      Stockboy.configuration.template_load_paths = [template_path]
    end

    describe ".read" do
      it "returns the template string" do
        TemplateFile.read("test_job").should match "# file exists!"
      end
    end

    describe ".template_path" do
      it "returns nil when missing" do
        TemplateFile.find("not_here").should be_nil
      end

      it "returns a file path when found" do
        TemplateFile.find("test_job").should == "#{template_path}/test_job.rb"
      end
    end

  end
end
