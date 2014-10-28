source 'https://rubygems.org'

# Specify your gem's dependencies the .gemspec
gemspec

gem 'rails', :github => 'rails', :branch => ENV['ACTIVE_RECORD_BRANCH'] if ENV['ACTIVE_RECORD_BRANCH']
gem 'rails', ENV['RAILS_VERSION'] if ENV['RAILS_VERSION']
