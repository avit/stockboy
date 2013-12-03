source 'https://rubygems.org'
gemspec

unless ENV["CI"]
  group :debug do
    gem "pry"
    gem "pry-debugger"
  end
end

group :doc do
  gem "redcarpet", "~> 1.0"
  gem "yard"
end

platforms :rbx do
  gem "rubysl-tracer", "~> 2.0"
  gem "rubysl", "~> 2.0"
  gem "racc"
end
