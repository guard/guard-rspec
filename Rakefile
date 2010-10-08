require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

namespace(:spec) do
  desc "Run all specs on multiple ruby versions (requires rvm)"
  task(:portability) do
    %w[1.8.7 1.9.2].each do |version|
      system <<-BASH
        bash -c 'source ~/.rvm/scripts/rvm;
                 rvm #{version};
                 echo "--------- version #{version} ----------\n";
                 bundle install;
                 rake spec:prepare_fixtures
                 rake spec'
      BASH
    end
  end
  
  desc "Run bundle install on each fixtures directories with Gemfile"
  task(:prepare_fixtures) do
    Dir.foreach("spec/fixtures") do |dir|
      if File.exists?("spec/fixtures/#{dir}/Gemfile")
        system <<-BASH
          cd spec/fixtures/#{dir};
          bundle install
        BASH
      end
    end
  end
end