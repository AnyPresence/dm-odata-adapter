require 'spec_helper'

describe DataMapper::Adapters::OdataAdapter do
  
  before :all do
   @adapter = DataMapper.setup(:default, :adapter => 'odata', :scheme => 'http', :host => 'services.odata.org', :path => '/AdventureWorksV3/AdventureWorks.svc')      
  end
  
  describe '#create' do
    it 'should not raise any errors' do
      lambda {
        Department.create(:name => 'engineering')
      }.should_not raise_error
    end

    it 'should set the identity field for the resource' do
      department = Department.new(:name => 'engineering')
      department.id.should be_nil
      department.save
      department.id.should_not be_nil
    end
  end

end
