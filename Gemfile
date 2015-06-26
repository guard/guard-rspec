source "https://rubygems.org"

if ENV["USE_INSTALLED_GUARD_RSPEC"] == "1"
  gem "guard-rspec"
  gem "launchy"
else
  gemspec
end

group :test do
  gem "coveralls", require: false
end

group :development do
  gem "rspec", "~> 3.1"
  gem "rubocop", require: false
  gem "guard-rubocop", require: false
  gem "guard-compat", ">= 0.0.2", require: false
end

group :tool do
  gem "ruby_gntp", require: false
end
