Guard::RSpec
=============

![travis-ci](http://travis-ci.org/guard/guard-rspec.png)

RSpec guard allows to automatically & intelligently launch specs when files are modified.

* Compatible with RSpec 1.x & RSpec 2.x (>= 2.4 needed for the notification feature)
* Tested on Ruby 1.8.6, 1.8.7, 1.9.2, JRuby & Rubinius.

Install
-------

Please be sure to have [Guard](https://github.com/guard/guard) installed before continue.

Install the gem:

    $ gem install guard-rspec

Add it to your Gemfile (inside test group):

``` ruby
gem 'guard-rspec'
```

Add guard definition to your Guardfile by running this command:

    $ guard init rspec

Usage
-----

Please read [Guard usage doc](https://github.com/guard/guard#readme)

Guardfile
---------

RSpec guard can be really adapted to all kind of projects.

### Standard RubyGem project

``` ruby
guard 'rspec' do
  watch(%r{^spec/.+_spec\.rb})
  watch(%r{^lib/(.+)\.rb})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb') { "spec" }
end
```

### Typical Rails app

``` ruby
guard 'rspec' do
  watch('spec/spec_helper.rb')                       { "spec" }
  watch('config/routes.rb')                          { "spec/routing" }
  watch('app/controllers/application_controller.rb') { "spec/controllers" }
  watch(%r{^spec/.+_spec\.rb})
  watch(%r{^app/(.+)\.rb})                           { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^lib/(.+)\.rb})                           { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^app/controllers/(.+)_(controller)\.rb})  { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }
end
```

Please read [Guard doc](https://github.com/guard/guard#readme) for more information about the Guardfile DSL.

Options
-------

By default, Guard::RSpec automatically detect your RSpec version (with the <tt>spec_helper.rb</tt> syntax or with Bundler) but you can force the version with the <tt>:version</tt> option:

``` ruby
guard 'rspec', :version => 2 do
  # ...
end
```

You can pass any of the standard RSpec CLI options using the <tt>:cli</tt> option:

``` ruby
guard 'rspec', :cli => "--color --format nested --fail-fast --drb" do
  # ...
end
```

Former <tt>:color</tt>, <tt>:drb</tt>, <tt>:fail_fast</tt> and <tt>:formatter</tt> options are thus deprecated and have no effect anymore.

### List of available options:

``` ruby
:version => 1               # force use RSpec version 1, default: 2
:cli => "-c -f doc"         # pass arbitrary RSpec CLI arguments, default: "-f progress"
:bundler => false           # don't use "bundle exec" to run the RSpec command, default: true
:rvm => ['1.8.7', '1.9.2']  # directly run your specs on multiple Rubies, default: nil
:notification => false      # don't display Growl (or Libnotify) notification after the specs are done running, default: true
:all_after_pass => false    # don't run all specs after changed specs pass, default: true
:all_on_start => false      # don't run all the specs at startup, default: true
:keep_failed => false       # keep failed specs until them pass, default: true
```

Notification
------------

The notification feature is only available for RSpec < 2, and RSpec >= 2.4 (due to the multiple-formatters feature that was present in RSpec 1, was removed in RSpec 2 and reintroduced in RSpec 2.4). So if you are using a version between 2 and 2.4, you should disable the notification with <tt>:notification => false</tt>. Otherwise, nothing will be displayed in the terminal when your specs will run.

The best solution is still to update RSpec to the latest version!

Formatters
----------

The <tt>:formatter</tt> option has been removed since CLI arguments can be passed through the <tt>:cli</tt> option. If you want to use the former Instafail formatter, you need to use <tt>{rspec-instafail}[http://rubygems.org/gems/rspec-instafail]</tt> gem instead:

``` ruby
# in your Gemfile
gem 'rspec-instafail'

# in your Guardfile
guard 'rspec', :cli => '-r rspec/instafail -f RSpec::Instafail' do
  # ...
end
```

Default formatter is the <tt>progress</tt> formatter (same as RSpec default).

Running a subset of all specs
-----------

The `:all_on_start` and `:all_after_pass` options cause all specs to be run.  If there
are some specs you want to skip, you can tag them with RSpec metadata (such as `:slow => true`)
and skip them with the cli `--tag` option (i.e. `--tag ~slow`).

Development
-----------

* Source hosted at [GitHub](https://github.com/guard/guard-rspec)
* Report issues/Questions/Feature requests on [GitHub Issues](https://github.com/guard/guard-rspec/issues)

Pull requests are very welcome! Make sure your patches are well tested. Please create a topic branch for every separate change
you make.

Testing
-------

Please run <tt>rake spec:prepare_fixtures</tt> once before launching specs.

Author
------

[Thibaud Guillaume-Gentil](https://github.com/thibaudgg)
