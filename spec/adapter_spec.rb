require 'spec_helper'

describe DataMapper::Adapters::OdataAdapter do
  
  before :all do

=begin #Setup for HANA xsodata source
   @adapter = DataMapper.setup(:default, :adapter => 'odata', :scheme => 'http', :host => 'ec2-54-221-211-251.compute-1.amazonaws.com', :port => 8000, :path => '/datamapper/datamapper/datamapper.xsodata', :username => ENV['ODATA_USERNAME'], :password => ENV['ODATA_PASSWORD'], :json_type => 'application/json;charset=utf-8', :builder => :Hana, :logging_level => 'debug')
=end   
=begin #Setup for NetWeaver OData source
   @adapter = DataMapper.setup(:default, :adapter => 'odata', :scheme => 'https', :host => 'sapes1.sapdevcenter.com', :path => '/sap/opu/odata/sap/ZGWSAMPLE_SRV/', :username => ENV['NETWEAVER_GATEWAY_USERNAME'], :password => ENV['NETWEAVER_GATEWAY_PASSWORD'], :json_type => 'application/json', :builder => :Netweaver, :enable_csrf_token => true, :logging_level => 'debug')
  
   service_url = "https://sapes1.sapdevcenter.com/sap/opu/odata/sap/ZGWSAMPLE_SRV/" 
   @service = OData::Service.new(service_url, :username => ENV['NETWEAVER_GATEWAY_USERNAME'], :password => ENV['NETWEAVER_GATEWAY_PASSWORD'])
   query = @service.ProductCollection
   #query.filter("ProductId eq 'HT-1000")
   results = @service.execute
=end
#   Product.all.each{|h| h.destroy }

   @adapter = DataMapper.setup(:default, :adapter => 'odata', :scheme => 'http', :host => 'ec2-54-205-112-205.compute-1.amazonaws.com', :path => '/DMApp/DMService.svc', :json_type => 'application/json', :logging_level => 'debug')

  end
  
  it_should_behave_like 'An Adapter'
end