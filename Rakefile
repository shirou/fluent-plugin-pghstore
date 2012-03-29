require "bundler/gem_tasks"

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
#  test.pattern = 'test/**/test_*.rb'
   test.test_files = FileList['test/**/test*.rb']
  test.verbose = true
end

task :default => :test

