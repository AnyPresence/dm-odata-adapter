# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dm-odata-adapter/version'

Gem::Specification.new do |spec|
  spec.name          = "dm-odata-adapter"
  spec.version       = OdataAdapter::VERSION
  spec.authors       = ["AnyPresence"]
  spec.email         = ["sales@anypresence.com"]
  spec.summary       = "DM adapter for OData based data sources."
  spec.homepage      = "https://github.com/AnyPresence/dm-odata-adapter"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  
#  spec.add_dependency "ruby_odata",     "~> 0.1.4"
  spec.add_dependency "datamapper",   "~> 1.2.0"
  spec.add_dependency "dm-serializer", "~> 1.2.0"
  
  spec.add_development_dependency "bundler", "~> 1.3.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "activesupport", "~> 3.2.14"
end
