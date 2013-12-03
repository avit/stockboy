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
