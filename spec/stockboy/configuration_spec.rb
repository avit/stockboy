require 'spec_helper'
require 'stockboy/configuration'

module Stockboy
  describe Configuration do

    subject(:config) { Stockboy::Configuration.new }

    it "yields a config block" do
      Stockboy::Configuration.new do |c|
        expect(c).to be_a Stockboy::Configuration
      end
    end

    it "is accessible from top namespace" do
      expect(Stockboy.configuration).to be_a Stockboy::Configuration
    end

    specify "#template_load_paths" do
      config.template_load_paths.clear
      config.template_load_paths << "/some_path"
      expect(config.template_load_paths).to eq ["/some_path"]
      config.template_load_paths = ["/other_path"]
      expect(config.template_load_paths).to eq ["/other_path"]
    end

  end
end
