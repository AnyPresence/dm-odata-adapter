source 'https://rubygems.org'

# Specify your gem's dependencies in dm-web-adapter.gemspec
gemspec

group :test do
  DM_VERSION = '~> 1.2.0'
  
  gem 'rake'
  gem 'rspec',          '~> 2.13.0',    :require => %w(spec)
  
  gem 'bundler',        '~> 1.3.5'
  gem 'dm-types', DM_VERSION
  gem "dm-core",  DM_VERSION
end