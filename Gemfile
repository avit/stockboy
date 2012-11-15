source :rubygems
gemspec

group :debug do
  gem "pry"
  gem "pry-nav"
  gem "pry-exception_explorer"
end

group :test do
  gem "guard-rspec"

  unless ENV['CI']
    gem "rb-fsevent"
    gem "ruby_gntp"
  end
end
