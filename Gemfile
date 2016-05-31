source "https://rubygems.org"

if ENV["USE_INSTALLED_GUARD_RSPEC"] == "1"
  gem "guard-rspec"
else
  gemspec development_group: :gem_build_tools
end

# bundler + rake - always included
group :gem_build_tools do
  gem "bundler", "~> 1.12", "< 2.0"
  gem "rake", "~> 11.1"
end

group :test do
  gem "coveralls", require: false
  gem "rspec", "~> 3.4"
  gem "launchy", "~> 2.4"
end

group :development do
  gem "rubocop", require: false
  gem "guard-rubocop", require: false
  gem "guard-compat", ">= 0.0.2", require: false
end

group :tool do
  gem "ruby_gntp", require: false
end
