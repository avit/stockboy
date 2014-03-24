source 'https://rubygems.org'
gemspec

unless ENV["CI"]
  group :debug do
    gem "pry"
  end
end

group :doc do
  gem "yard"
  gem "kramdown"
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
