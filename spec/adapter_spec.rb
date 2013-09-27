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

   @adapter = DataMapper.setup(:default, :adapter => 'odata', :scheme => 'http', :host => 'ec2-54-227-116-63.compute-1.amazonaws.com/', :path => '/DataMapperOData/WcfDataService1.svc', :json_type => 'application/json', :logging_level => 'debug')
   ::Item.all.each{|h| puts "\n#{h.inspect}" }
  end

  describe '#create' do
    it 'should not raise any errors' do
      lambda {
        item_model.create(:id => 'peach', :quantity => 2)
      }.should_not raise_error
    end

    it 'should set the identity field for the resource' do
      heffalump = item_model.new(:id => 'peach2', :quantity => 4)
      heffalump.save
      heffalump.id.should_not be_nil
    end
  end
  
  describe '#read' do
    before :all do
      @item = item_model.create(:id => 'brownish hue', :quantity => 1)
    end

    it 'should not raise any errors' do
      lambda {
        item_model.all()
      }.should_not raise_error
    end

    it 'should return stuff' do
      item_model.all.should be_include(@item)
    end
  end
    
  describe '#update' do
    before do
      @item = item_model.create(:id => 'indigo', :quantity => 2)
    end

    it 'should not raise any errors' do
      lambda {
        @item.quantity = 4
        @item.save
      }.should_not raise_error
    end

    it 'should not alter the identity field' do
      id = @item.id
      @item.quantity = 7
      @item.save
      @item.id.should == id
    end

    it 'should update altered fields' do
      @item.quantity = 8
      @item.save
      item_model.get(*@item.key).quantity.should == 8
    end

    it 'should not alter other fields' do
      quantity = @item.quantity
      @item.quantity = 2
      @item.save
      item_model.get(*@item.key).quantity.should == quantity
    end
  end
  
  describe '#delete' do
    before do
      @item = item_model.create(:id => 'forest green', :quantity => 2)
    end

    it 'should not raise any errors' do
      lambda {
        @item.destroy
      }.should_not raise_error
    end

    it 'should delete the requested resource' do
      id = @item.id
      @item.destroy
      item_model.get(id).should be_nil
    end
  end

  describe 'query matching' do
    before :all do
      @red  = item_model.create(:id => 'red')
      @two  = item_model.create(:id => 'twosie', :quantity => 2)
      @five = item_model.create(:id => 'fivesie', :quantity => 5)
    end

    describe 'conditions' do
      describe 'eql' do
        it 'should be able to search for objects included in an inclusive range of values' do
          item_model.all(:quantity => 1..5).should be_include(@five)
        end

        it 'should be able to search for objects included in an exclusive range of values' do
          item_model.all(:quantity => 1...6).should be_include(@five)
        end

        it 'should not be able to search for values not included in an inclusive range of values' do
          item_model.all(:quantity => 1..4).should_not be_include(@five)
        end

        it 'should not be able to search for values not included in an exclusive range of values' do
          item_model.all(:quantity => 1...5).should_not be_include(@five)
        end
      end

      describe 'not' do
        it 'should be able to search for objects with not equal value' do
          item_model.all(:id.not => 'red').should_not be_include(@red)
        end

        it 'should include objects that are not like the value' do
          item_model.all(:id.not => 'black').should be_include(@red)
        end

        it 'should be able to search for objects with not nil value' do
          item_model.all(:id.not => nil).should be_include(@red)
        end

        it 'should not include objects with a nil value' do
          item_model.all(:id.not => nil).should_not be_include(@two)
        end

        it 'should be able to search for object with a nil value using required properties' do
          item_model.all(:id.not => nil).should == [ @red, @two, @five ]
        end

        it 'should be able to search for objects not in an empty list (match all)' do
          item_model.all(:id.not => []).should == [ @red, @two, @five ]
        end

        it 'should be able to search for objects in an empty list and another OR condition (match none on the empty list)' do
          item_model.all(
            :conditions => DataMapper::Query::Conditions::Operation.new(
              :or,
              DataMapper::Query::Conditions::Comparison.new(:in, item_model.properties[:id], []),
              DataMapper::Query::Conditions::Comparison.new(:in, item_model.properties[:quantity], [5])
            )
          ).should == [ @five ]
        end

        it 'should be able to search for objects not included in an array of values' do
          item_model.all(:quantity.not => [ 1, 3, 5, 7 ]).should be_include(@two)
        end

        it 'should be able to search for objects not included in an array of values' do
          item_model.all(:quantity.not => [ 1, 3, 5, 7 ]).should_not be_include(@five)
        end

        it 'should be able to search for objects not included in an inclusive range of values' do
          item_model.all(:quantity.not => 1..4).should be_include(@five)
        end

        it 'should be able to search for objects not included in an exclusive range of values' do
          item_model.all(:quantity.not => 1...5).should be_include(@five)
        end

        it 'should not be able to search for values not included in an inclusive range of values' do
          item_model.all(:quantity.not => 1..5).should_not be_include(@five)
        end

        it 'should not be able to search for values not included in an exclusive range of values' do
          item_model.all(:quantity.not => 1...6).should_not be_include(@five)
        end
      end
    end
  end
end