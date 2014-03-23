source 'https://rubygems.org'
gemspec

unless ENV["CI"]
  group :debug do
    gem "pry"
    gem "pry-debugger" if RUBY_VERSION.start_with? "1.9"
    gem "pry-byebug" if RUBY_VERSION.start_with? "2."
  end
end

group :doc do
  gem "redcarpet", "~> 1.0"
  gem "yard"
end

group :test do
  gem "simplecov", require: nil
  gem "codeclimate-test-reporter", require: nil
end

platforms :rbx do
  gem "rubysl-tracer", "~> 2.0"
  gem "rubysl", "~> 2.0"
  gem "racc"
end
