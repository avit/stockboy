if ENV['CI']
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
end

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter "/spec/"
    add_group "Providers", "/providers/"
    add_group "Readers", "/readers/"
    add_group "Translations", "/translations/"
  end
end

if ENV['DEBUG']
  require 'pry'
end

require 'rspec/its'
require 'ostruct'
require 'savon'
require 'savon/mock/spec_helper'
require 'pathname'
# require 'vcr'

$:.unshift File.expand_path('../lib/stockboy/lib', __FILE__)

RSpec.configure do |config|
  config.include Savon::SpecHelper
  config.mock_with :rspec
  spec_fixtures = File.expand_path("fixtures", File.dirname(__FILE__))
  config.add_setting :fixture_path, default: Pathname(spec_fixtures)

  config.before :suite do
    require 'stockboy/configuration'
    Stockboy.configure do |c|
      c.logger = Logger.new(StringIO.new)
    end
  end

  module Helpers
    def fixture_path(*args)
      RSpec.configuration.fixture_path.join(*args)
    end
  end

  config.include Helpers
end

# VCR.configure do |c|
#   c.cassette_library_dir = 'fixtures/vcr_cassettes'
#   # c.hook_into :fakeweb # or :fakeweb
# end
