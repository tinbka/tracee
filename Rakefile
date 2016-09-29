require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new :spec do |t|
  t.rspec_opts = '-f progress --deprecation-out /dev/null'
end

task :build => :spec