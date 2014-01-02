# Guard::RSpec

[![Gem Version](https://badge.fury.io/rb/guard-rspec.png)](http://badge.fury.io/rb/guard-rspec) [![Build Status](https://secure.travis-ci.org/guard/guard-rspec.png?branch=master)](http://travis-ci.org/guard/guard-rspec) [![Dependency Status](https://gemnasium.com/guard/guard-rspec.png)](https://gemnasium.com/guard/guard-rspec) [![Code Climate](https://codeclimate.com/github/guard/guard-rspec.png)](https://codeclimate.com/github/guard/guard-rspec) [![Coverage Status](https://coveralls.io/repos/guard/guard-rspec/badge.png?branch=master)](https://coveralls.io/r/guard/guard-rspec)

Guard::RSpec allows to automatically & intelligently launch specs when files are modified.

* Compatible with RSpec >2.14 & 3
* Tested against Ruby 1.9.3, 2.0.0, JRuby and Rubinius.

## Install

Add the gem to your Gemfile (inside development group):

``` ruby
 gem 'guard-rspec', require: false
```

Add guard definition to your Guardfile by running this command:

```
$ guard init rspec
```

## Usage

Please read [Guard usage doc](https://github.com/guard/guard#readme).

## Guardfile

Guard::RSpec can be adapted to all kinds of projects, some examples:

### Standard RubyGem project

``` ruby
guard :rspec do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end
```

### Typical Rails app

``` ruby
guard :rspec do
  watch('spec/spec_helper.rb')                        { "spec" }
  watch('config/routes.rb')                           { "spec/routing" }
  watch('app/controllers/application_controller.rb')  { "spec/controllers" }
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^app/(.*)(\.erb|\.haml|\.slim)$})          { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
  watch(%r{^lib/(.+)\.rb$})                           { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }
end
```

Please read [Guard doc](https://github.com/guard/guard#readme) for more information about the Guardfile DSL.

## Options

Guard::RSpec 4.0 use now a more simple approach with the new `cmd` option that let you precisely define which rspec command will be launched on each run. As example if you want to support Spring with a custom formatter (progress by default) use:

``` ruby
guard :rspec, cmd: 'spring rspec -f doc' do
  # ...
end
```

### Running with bundler

Running `bundle exec guard` will not run the specs with bundler. You need to change the `cmd` option to `bundle exec rspec`:

``` ruby
guard :rspec, cmd: 'bundle exec rspec' do
  # ...
end
```

### List of available options:

``` ruby
cmd: 'zeus rspec'      # Specify a custom rspec command to run, default: 'rspec'
spec_paths: ['spec']   # Specify a custom array of paths that contain spec files
failed_mode: :focus    # What to do with failed specs
                       # Available values:
                       #  :focus (default) - focus on the first 10 failed specs, rerun till they pass
                       #  :keep - keep failed specs until they pass (add them to new ones)
                       #  :none - just report
all_after_pass: true   # Run all specs after changed specs pass, default: false
all_on_start: true     # Run all the specs at startup, default: false
launchy: nil           # Pass a path to an rspec results file, e.g. ./tmp/spec_results.html
notification: false    # Display notification after the specs are done running, default: true
run_all: { cmd: 'custom rspec command', message: 'custom message' } # Custom options to use when running all specs
```

### Using Launchy to view rspec results

guard-rspec can be configured to launch a results file in lieu of outputing rspec results to the terminal.
Configure your Guardfile with the launchy option:

``` ruby
guard :rspec, cmd: 'rspec -f html -o ./tmp/spec_results.html', launchy: './tmp/spec_results.html' do
  # ...
end
```

## Development

* Documentation hosted at [RubyDoc](http://rubydoc.info/github/guard/guard-rspec/master/frames).
* Source hosted at [GitHub](https://github.com/guard/guard-rspec).

Pull requests are very welcome! Please try to follow these simple rules if applicable:

* Please create a topic branch for every separate change you make.
* Make sure your patches are well tested. All specs run with `rake spec:portability` must pass.
* Update the [README](https://github.com/guard/guard-rspec/blob/master/README.md).
* Please **do not change** the version number.

For questions please join us in our [Google group](http://groups.google.com/group/guard-dev) or on
`#guard` (irc.freenode.net).

### Author

[Thibaud Guillaume-Gentil](https://github.com/thibaudgg) ([@thibaudgg](https://twitter.com/thibaudgg))

### Contributors

[https://github.com/guard/guard-rspec/contributors](https://github.com/guard/guard-rspec/contributors)
