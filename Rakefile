require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

# We define a custom_spec that is default because it depends on the spec:prepare_fixtures task
# This way, CI servers should execute the spec:prepare_fixtures before the spec task, allowing all specs to pass!
task :custom_spec => "spec:prepare_fixtures" do
  system 'rake spec'
end
task :default => :custom_spec

namespace :spec do

  desc "Run bundle install on each fixtures directories with Gemfile"
  task :prepare_fixtures do
    Dir.foreach("spec/fixtures") do |dir|
      if File.exists?("spec/fixtures/#{dir}/Gemfile")
        system <<-BASH
          cd spec/fixtures/#{dir};
          bundle install;
        BASH
      end
    end
  end

end
