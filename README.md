dm-odata-adapter
================

DM adapter for OData sources. It supports OData V2 and utilizes the Ruby_Odata gem to make service calls.
While support for Microsoft type implementations is fairly complete, support for SAP Netweaver and HANA backed implementations is limited due to the incomplete nature of these implementations.

Usage
================

To use the adapter against a Microsoft backed implementation, which is the default, setup a DataMapper adapter like so:
```
DataMapper.setup(:default, :adapter => 'odata', :scheme => 'http', :host => ENV['ODATA_HOST'], :path => ENV['ODATA_PATH'], :json_type => 'application/json', :username => ENV['ODATA_USERNAME'], :password => ENV['ODATA_PASSWORD'])

```
To specify other implementations, you would use :builder configuration option. For example, using an SAP HANA backed service looks something like the following:

```
DataMapper.setup(:default, :adapter => 'odata', :scheme => 'http', :host => ENV['ODATA_HOST'], :port => 8000, :path => ENV['ODATA_PATH'], :username => ENV['ODATA_USERNAME'], :password => ENV['ODATA_PASSWORD'], :json_type => 'application/json;charset=utf-8', :builder => 'Hana')
```