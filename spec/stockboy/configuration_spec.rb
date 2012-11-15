require 'spec_helper'
require 'stockboy/configuration'

module Stockboy
  describe Configuration do

    subject(:config)

    it "yields a config block" do
      Stockboy::Configuration.new do |c|
        c.should be_a Stockboy::Configuration
      end
    end

    it "is accessible from top namespace" do
      Stockboy.configuration.should be_a Stockboy::Configuration
    end

    specify "#template_load_paths" do
      config.template_load_paths.clear
      config.template_load_paths << "/some_path"
      config.template_load_paths.should == ["/some_path"]
      config.template_load_paths = ["/other_path"]
      config.template_load_paths.should == ["/other_path"]
    end

  end
end
