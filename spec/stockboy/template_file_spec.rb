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
        expect(TemplateFile.read("test_job")).to match "# file exists!"
      end
    end

    describe ".template_path" do
      it "returns nil when missing" do
        expect(TemplateFile.find("not_here")).to be nil
      end

      it "returns a file path when found" do
        expect(TemplateFile.find("test_job")).to eq "#{template_path}/test_job.rb"
      end
    end

  end
end
