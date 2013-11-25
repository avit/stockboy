#
# Bundler
#

require "bundler/gem_tasks"

#
# RSpec
#

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new

#
# YARD
#

require "yard/rake/yardoc_task"
YARD::Rake::YardocTask.new do |t|
  # t.options += ['--title', "Stockboy Documentation"]
end

#
# Yardstick
#

require 'yardstick/rake/measurement'
require 'yardstick/rake/verify'

Yardstick::Rake::Measurement.new(:yardstick_measure) do |measurement|
  measurement.output = 'measurement/report.txt'
end

Yardstick::Rake::Verify.new do |verify|
  verify.threshold = 100
end

#
# Stockboy
#

task :default => :spec

task :test => :spec
