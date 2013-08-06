require 'dm-core'
require 'ruby_odata'
require 'dm-odata-adapter/transformer'
require 'dm-odata-adapter/odata_adapter'

::DataMapper::Adapters.const_added(:OdataAdapter)
