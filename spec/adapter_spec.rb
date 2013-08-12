require 'spec_helper'

describe DataMapper::Adapters::OdataAdapter do
  
  before :all do

   @adapter = DataMapper.setup(:default, :adapter => 'odata', :scheme => 'http', :host => 'ec2-54-221-211-251.compute-1.amazonaws.com', :port => 8000, :path => '/datamapper/datamapper/datamapper.xsodata', :username => "SYSTEM", :password => 'P455w0rd', :json_type => 'application/json;charset=utf-8')
  end
  
  describe '#create' do
    it 'should not raise any errors' do
      lambda {
        Heffalump.create(:color => 'Blue', :num_spots => 6)
      }.should_not raise_error
    end

    it 'should set the identity field for the resource' do
      heffalump =  Heffalump.new(:color => 'Orange')
      heffalump.id.should be_nil
      heffalump.save
      heffalump.id.should_not be_nil
    end

  end
end