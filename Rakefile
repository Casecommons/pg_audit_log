require 'bundler'
Bundler::GemHelper.install_tasks

task :autotest do
  sh "bundle update && autotest -s rspec2"
end