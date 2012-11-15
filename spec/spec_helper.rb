require 'pry'
require 'pry-nav'
require 'pry-exception_explorer'
require 'ostruct'
require 'savon_spec'
require 'log4r'
# require 'vcr'

$:.unshift File.expand_path('../lib/stockboy/lib', __FILE__)

Savon::Spec::Fixture.path = File.expand_path("./fixtures/soap", File.dirname(__FILE__))

RSpec.configure do |config|
  config.include Savon::Spec::Macros
  config.mock_with :rspec
  spec_fixtures = File.expand_path("fixtures", File.dirname(__FILE__))
  config.add_setting :fixture_path, default: Pathname(spec_fixtures)
end

Log4r::Logger.global.outputters = Log4r::Outputter.stdout

# VCR.configure do |c|
#   c.cassette_library_dir = 'fixtures/vcr_cassettes'
#   # c.hook_into :fakeweb # or :fakeweb
# end
