# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'guard/rspec/version'

Gem::Specification.new do |s|
  s.name        = 'guard-rspec'
  s.version     = Guard::RSpecVersion::VERSION
  s.author      = 'Thibaud Guillaume-Gentil'
  s.email       = 'thibaud@thibaud.gg'
  s.summary     = 'Guard gem for RSpec'
  s.description = 'Guard::RSpec automatically run your specs (much like autotest).'
  s.homepage    = 'https://rubygems.org/gems/guard-rspec'
  s.license     = 'MIT'

  s.files        = `git ls-files`.split($/)
  s.test_files   = s.files.grep(%r{^spec/})
  s.require_path = 'lib'

  s.add_dependency 'guard', '~> 2.1'
  s.add_dependency 'rspec', '>= 2.14', '< 4.0'

  s.add_development_dependency 'bundler', '>= 1.3.5', '< 2.0'
  s.add_development_dependency 'rake', '~> 10.1'
  s.add_development_dependency 'launchy', '~> 2.4'
end
