require 'rubygems'
require 'rake'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'cucumber/rake/task'
Cucumber::Rake::Task.new

namespace :spec do
  desc "Run specs that don't talk to services"
  RSpec::Core::RakeTask.new(:focus) do |t|
    t.rspec_opts = '-t ~integration'
  end

  desc "Run integration (adapter) specs. These require configuration in config/ungulate.rb"
  RSpec::Core::RakeTask.new(:integration) do |t|
    t.rspec_opts = '-t integration'
  end
end

task :default => 'spec:focus'
