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

require 'yard'
require "yard/rake/yardoc_task"
YARD::Rake::YardocTask.new do |t|
  # t.options += ['--title', "Stockboy Documentation"]
end

#
# Stockboy
#

task :default => :spec

task :test => :spec
