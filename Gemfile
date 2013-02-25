source 'https://rubygems.org'
gemspec

group :debug do
  gem "pry"
  gem "pry-debugger"
end

group :test do
  gem "guard-rspec"

  unless ENV['CI']
    gem "rb-fsevent"
    gem "ruby_gntp"
  end
end
