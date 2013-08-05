require 'spec_helper'

describe DataMapper::Adapters::OdataAdapter do
  
  before :all do
   @adapter = DataMapper.setup(:default, :adapter => 'odata', :scheme => 'http', :host => 'localhost', :port => '8181', :path => '/sqlconnector/data/conn/live.rsc/dbo.heffalumps'
   )      
  end
  
  it_should_behave_like 'An Adapter'

end