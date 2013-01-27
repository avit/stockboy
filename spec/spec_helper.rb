require 'pry'
require 'pry-debugger'
require 'ostruct'
require 'log4r'
require 'savon'
require 'savon/mock/spec_helper'
# require 'vcr'

$:.unshift File.expand_path('../lib/stockboy/lib', __FILE__)

RSpec.configure do |config|
  config.include Savon::SpecHelper
  config.mock_with :rspec
  spec_fixtures = File.expand_path("fixtures", File.dirname(__FILE__))
  config.add_setting :fixture_path, default: Pathname(spec_fixtures)
end

Log4r::Logger.global.outputters = Log4r::Outputter.stdout

# VCR.configure do |c|
#   c.cassette_library_dir = 'fixtures/vcr_cassettes'
#   # c.hook_into :fakeweb # or :fakeweb
# end
