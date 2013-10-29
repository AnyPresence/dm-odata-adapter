require 'rubygems'
require 'pathname'

# Support running specs with 'rake spec' and 'spec'
$LOAD_PATH.unshift('lib') unless $LOAD_PATH.include?('lib')

require 'dm-odata-adapter'
require 'dm-core/spec/shared/adapter_spec'

ROOT = Pathname(__FILE__).dirname.parent

Pathname.glob((ROOT + 'spec/fixtures/**/*.rb').to_s).each { |file| require file }
Pathname.glob((ROOT + 'spec/**/shared/**/*.rb').to_s).each { |file| require file }

ENV['ADAPTER'] = 'odata'
ENV['ADAPTER_SUPPORTS'] = 'all'

DataMapper.finalize

def heffalump_model
  V2::Floppy
end