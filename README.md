# Guard::RSpec
[![Gem Version](https://badge.fury.io/rb/guard-rspec.png)](http://badge.fury.io/rb/guard-rspec) [![Build Status](https://secure.travis-ci.org/guard/guard-rspec.png?branch=master)](http://travis-ci.org/guard/guard-rspec) [![Dependency Status](https://gemnasium.com/guard/guard-rspec.png)](https://gemnasium.com/guard/guard-rspec) [![Code Climate](https://codeclimate.com/github/guard/guard-rspec.png)](https://codeclimate.com/github/guard/guard-rspec) [![Coverage Status](https://coveralls.io/repos/guard/guard-rspec/badge.png?branch=master)](https://coveralls.io/r/guard/guard-rspec)

RSpec guard allows to automatically & intelligently launch specs when files are modified.

* Compatible with RSpec >= 2.13 (use guard-rspec 1.2.x for older release, including RSpec 1.x)
* Tested against Ruby 1.8.7, 1.9.2, 1.9.3, 2.0.0, Ruby head, REE, JRuby (1.8 mode, 1.9 mode & head) & Rubinius (1.8 mode, 1.9 mode & head).

## Install

Please be sure to have [Guard](https://github.com/guard/guard) installed before continuing.

Install the gem:

```
$ gem install guard-rspec
```

Add it to your Gemfile (inside development group):

``` ruby
group :development do
  gem 'guard-rspec'
end
```

Add guard definition to your Guardfile by running this command:

```
$ guard init rspec
```

## Usage

Please read [Guard usage doc](https://github.com/guard/guard#readme).

## Guardfile

RSpec guard can be adapted to all kinds of projects.

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
  watch(%r{^app/(.*)(\.erb|\.haml)$})                 { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
  watch(%r{^lib/(.+)\.rb$})                           { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }
end
```

Please read [Guard doc](https://github.com/guard/guard#readme) for more information about the Guardfile DSL.

## Options

You can pass any of the standard RSpec CLI options using the `:cli` option:

``` ruby
guard 'rspec', :cli => "--color --format nested --fail-fast --drb" do
  # ...
end
```

By default, Guard::RSpec will only look for spec files within `spec` in your project root. You can configure Guard::RSpec to look in additional paths by using the `:spec_paths` option:

``` ruby
guard 'rspec', :spec_paths => ["spec", "vendor/engines/reset/spec"] do
  # ...
end
```
If you have only one path to look in, you can configure the `:spec_paths` option with a string:

``` ruby
guard 'rspec', :spec_paths => "test" do
  # ...
end
```
If you want to set an environment variable, you can configure the `:env` option with a hash:

``` ruby
guard 'rspec', :env => {'RAILS_ENV' => 'guard'} do
  # ...
end
```
[Turnip](https://github.com/jnicklas/turnip) is supported (Ruby 1.9.X only), but you must enable it:
``` ruby
guard 'rspec', :turnip => true do
  # ...
end
```
[Spring](https://github.com/jonleighton/spring) is supported (Ruby 1.9.X / Rails 3.2+ only), but you must enable it:
``` ruby
guard 'rspec', :spring => true do
  # ...
end
```
[ParallelTests](https://github.com/grosser/parallel_tests) is supported, but you must enable it:
``` ruby
guard 'rspec', :parallel => true, :parallel_cli => '-n 2' do
  # ...
end
```
[Foreman](https://github.com/ddollar/foreman) is supported, but you must enable it:
``` ruby
guard 'rspec', :foreman => true do
  # ...
end
```

Former `:color`, `:drb`, `:fail_fast` and `:formatter` options are deprecated and no longer have effect.

### List of available options:

``` ruby
:cli => "-c -f doc"          # pass arbitrary RSpec CLI arguments, default: "-f progress"
:bundler => false            # use "bundle exec" to run the RSpec command, default: true
:binstubs => true            # use "bin/rspec" to run the RSpec command (takes precedence over :bundle), default: false
:rvm => ['1.8.7', '1.9.2']   # directly run your specs on multiple Rubies, default: nil
:notification => false       # display Growl (or Libnotify) notification after the specs are done running, default: true
:all_after_pass => true     # run all specs after changed specs pass, default: false
:all_on_start => true       # run all the specs at startup, default: false
:keep_failed => true        # keep failed specs until they pass, default: false
:run_all => { :cli => "-p", :parallel => true, :parallel_cli => '-n 2' } # cli arguments to use when running all specs, default: same as :cli; parallel_rspec arguments, default:  same as :parallel_cli
:spec_paths => ["spec"]      # specify an array of paths that contain spec files
:exclude => "spec/foo/**/*"  # exclude files based on glob
:spring => true              # enable spring support; default: false
:turnip => true              # enable turnip support; default: false
:zeus => true                # enable zeus support; default: false
:foreman => true             # enable foreman support; default: false
:focus_on_failed => false    # focus on the first 10 failed specs first, rerun till they pass
:parallel => true            # run all specs in parallel using [ParallelTests](https://github.com/grosser/parallel_tests) gem, default: false
:parallel_cli => "-n 2"      # pass arbitrary Parallel Tests arguments, default: ""
```

You can also use a custom binstubs directory using `:binstubs => 'some-dir'`.

### DRb mode

When you specify `--drb` within `:cli`, guard-rspec will circumvent the `rspec` command line tool by
directly communicating with the RSpec DRb server.  This avoids the extra overhead incurred by your
shell, bundler and loading RSpec's environment just to send a DRb message. It shaves off a
second or two before the specs start to run; they should run almost immediately.

## Notification

The notification feature is only available for RSpec < 2, and RSpec >= 2.4 (due to the multiple-formatters feature that was present in RSpec 1, was removed in RSpec 2 and reintroduced in RSpec 2.4). So if you are using a version between 2 and 2.4, you should disable the notification with <tt>:notification => false</tt>. Otherwise, nothing will be displayed in the terminal when your specs will run.

Note that setting the environment variable `SPEC_OPTS` can cause notifications to fail.

The best solution is still to update RSpec to the latest version!

## Formatters

The `:formatter` option has been removed since CLI arguments can be passed through the `:cli` option. If you want to use the former Instafail formatter, you need to use the [rspec-instafail](http://rubygems.org/gems/rspec-instafail) gem instead:

``` ruby
# in your Gemfile
gem 'rspec-instafail'

# in your Guardfile
guard 'rspec', :cli => '-r rspec/instafail -f RSpec::Instafail' do
  # ...
end
```

Default formatter is the `progress` formatter (same as RSpec default).

## Running a subset of all specs

The `:all_on_start` and `:all_after_pass` options cause all specs located in the `spec` directory to be run. If there
are some specs you want to skip, you can tag them with RSpec metadata (such as `:slow => true`)
and skip them with the cli `--tag` option (i.e. `--tag ~slow`).

You can also use option :spec_paths to override paths used when running all specs.
You can use this feature to create multiple groups of guarded specs with distinct paths, and execute each in its own process:

``` ruby
# in your Guardfile
group 'acceptance-tests' do
  guard 'rspec', :spec_paths => ['spec/acceptance'] do
    # ...
  end
end

group 'unit-tests' do
  guard 'rspec', :spec_paths => ['spec/models', 'spec/controllers', 'spec/routing'] do
    # ...
  end
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

### Testing

Please run `rake spec:prepare_fixtures` once before launching specs.

### Author

[Thibaud Guillaume-Gentil](https://github.com/thibaudgg) ([@thibaudgg](http://twitter.com/thibaudgg))

### Contributors

[https://github.com/guard/guard-rspec/contributors](https://github.com/guard/guard-rspec/contributors)
