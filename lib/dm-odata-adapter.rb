require 'dm-core'
require 'ruby_odata'
require 'securerandom'
require 'dm-odata-adapter/transformer'
require 'dm-odata-adapter/builder'
require 'dm-odata-adapter/odata_adapter'

::DataMapper::Adapters.const_added(:OdataAdapter)
