require "bundler/gem_tasks"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)
task default: :spec

namespace :test do
  desc "Locally run tests like Travis and HoundCI would"
  task :all_versions do
    system(*%w(bundle install --quiet)) || abort
    system(*%w(bundle update --quiet)) || abort
    system(*%w(bundle exec rubocop -c .hound.yml)) || abort

    gemfiles = Dir["gemfiles/Gemfile.rspec-*"]

    actual_gemfiles = gemfiles.select { |f| /\d\.\d{1,2}$/ =~ f }
    actual_gemfiles.each do |gemfile|
      STDOUT.puts
      STDOUT.puts "----------------------------------------------------- "
      STDOUT.puts " >> Running tests using Gemfile: #{gemfile} <<"
      STDOUT.puts "----------------------------------------------------- "
      env = { "BUNDLE_GEMFILE" => gemfile }
      system(env, *%w(bundle install --quiet)) || abort
      system(env, *%w(bundle update --quiet)) || abort
      system(env, *%w(bundle exec rspec)) || abort
    end
  end
end
