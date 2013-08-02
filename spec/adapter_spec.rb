require 'spec_helper'

describe DataMapper::Adapters::OdataAdapter do
  
  before :all do
   @adapter = DataMapper.setup(:default, :adapter => 'odata', :scheme => 'http', :host => 'services.odata.org', :path => '/v3/odata/odata.svc'
   )      
  end
  
  it_should_behave_like 'An Adapter'

end