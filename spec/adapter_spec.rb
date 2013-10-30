require 'spec_helper'

describe DataMapper::Adapters::OdataAdapter do
  
  before :all do

=begin #Setup for HANA xsodata source
   @adapter = DataMapper.setup(:default, :adapter => 'odata', :scheme => 'http', :host => 'ec2-54-221-211-251.compute-1.amazonaws.com', :port => 8000, :path => '/datamapper/datamapper/datamapper.xsodata', :username => ENV['ODATA_USERNAME'], :password => ENV['ODATA_PASSWORD'], :json_type => 'application/json;charset=utf-8', :builder => 'Hana', :logging_level => 'debug')
=end   
=begin #Setup for NetWeaver OData source
   @adapter = DataMapper.setup(:default, :adapter => 'odata', :scheme => 'https', :host => 'sapes1.sapdevcenter.com', :path => '/sap/opu/odata/sap/ZGWSAMPLE_SRV/', :username => ENV['NETWEAVER_GATEWAY_USERNAME'], :password => ENV['NETWEAVER_GATEWAY_PASSWORD'], :json_type => 'application/json', :builder => 'Netweaver', :enable_csrf_token => true, :logging_level => 'debug')
  
   service_url = "https://sapes1.sapdevcenter.com/sap/opu/odata/sap/ZGWSAMPLE_SRV/" 
   @service = OData::Service.new(service_url, :username => ENV['NETWEAVER_GATEWAY_USERNAME'], :password => ENV['NETWEAVER_GATEWAY_PASSWORD'])
   query = @service.ProductCollection
   #query.filter("ProductId eq 'HT-1000")
   results = @service.execute
=end
#   Product.all.each{|h| h.destroy }

   @adapter = DataMapper.setup(:default, :adapter => 'odata', :scheme => 'http', :host => 'ec2-50-17-10-15.compute-1.amazonaws.com', :path => '/DMApp/DMService.svc', :json_type => 'application/json', :builder => 'microsoft', :username => ENV['ODATA_USERNAME'], :password => ENV['ODATA_PASSWORD'])
   heffalump_model.all.each{|h| h.destroy }
  end
  
  describe '#create' do
    it 'should not raise any errors' do
      lambda {
        heffalump_model.create(:the_color => 'peach')
      }.should_not raise_error
    end

    it 'should set the identity field for the resource' do
      heffalump = heffalump_model.new(:the_color => 'peach')
      heffalump.the_id.should be_nil
      heffalump.save
      heffalump.the_id.should_not be_nil
    end
  end
  
  describe '#read' do
    before :all do
      @heffalump = heffalump_model.create(:the_color => 'brownish hue')
    end

    it 'should not raise any errors' do
      lambda {
        heffalump_model.all()
      }.should_not raise_error
    end

    it 'should return stuff' do
      heffalump_model.all.should be_include(@heffalump)
    end
  end
  describe '#update' do
    before do
      @heffalump = heffalump_model.create(:the_color => 'indigo')
    end

    it 'should not raise any errors' do
      lambda {
        @heffalump.the_color = 'violet'
        @heffalump.save
      }.should_not raise_error
    end

    it 'should not alter the identity field' do
      id = @heffalump.the_id
      @heffalump.the_color = 'violet'
      @heffalump.save
      @heffalump.the_id.should == id
    end

    it 'should update altered fields' do
      @heffalump.the_color = 'violet'
      @heffalump.save
      heffalump_model.get(*@heffalump.key).the_color.should == 'violet'
    end

    it 'should not alter other fields' do
      color = @heffalump.the_color
      @heffalump.number_of_spots = 3
      @heffalump.save
      heffalump_model.get(*@heffalump.key).the_color.should == color
    end
  end   
  
  describe '#delete' do
    before do
      @heffalump = heffalump_model.create(:the_color => 'forest green')
    end

    it 'should not raise any errors' do
      lambda {
        @heffalump.destroy
      }.should_not raise_error
    end

    it 'should delete the requested resource' do
      id = @heffalump.the_id
      @heffalump.destroy
      heffalump_model.get(id).should be_nil
    end
  end
  
  describe 'query matching' do
    before :all do
      heffalump_model.all.each{|h| h.destroy }
      @red  = heffalump_model.create(:the_color => 'red')
      @two  = heffalump_model.create(:number_of_spots => 2)
      @five = heffalump_model.create(:number_of_spots => 5)
    end

    describe 'conditions' do
      describe 'eql' do
        it 'should be able to search for objects included in an inclusive range of values' do
          heffalump_model.all(:number_of_spots => 1..5).should be_include(@five)
        end

        it 'should be able to search for objects included in an exclusive range of values' do
          heffalump_model.all(:number_of_spots => 1...6).should be_include(@five)
        end

        it 'should not be able to search for values not included in an inclusive range of values' do
          heffalump_model.all(:number_of_spots => 1..4).should_not be_include(@five)
        end

        it 'should not be able to search for values not included in an exclusive range of values' do
          heffalump_model.all(:number_of_spots => 1...5).should_not be_include(@five)
        end
      end

      describe 'not' do
        it 'should be able to search for objects with not equal value' do
          heffalump_model.all(:the_color.not => 'red').should_not be_include(@red)
        end

        it 'should include objects that are not like the value' do
          heffalump_model.all(:the_color.not => 'black').should be_include(@red)
        end

        it 'should be able to search for objects with not nil value' do
          heffalump_model.all(:the_color.not => nil).should be_include(@red)
        end

        it 'should not include objects with a nil value' do
          heffalump_model.all(:the_color.not => nil).should_not be_include(@two)
        end

        it 'should be able to search for object with a nil value using required properties' do
          heffalump_model.all(:the_id.not => nil).should == [ @red, @two, @five ]
        end

        it 'should be able to search for objects not in an empty list (match all)' do
          # Apparently, this test is too fancy for OData, heffalump_model.all(:the_color.not => []).should == [ @red, @two, @five ]
        end

        it 'should be able to search for objects in an empty list and another OR condition (match none on the empty list)' do
          heffalump_model.all(
            :conditions => DataMapper::Query::Conditions::Operation.new(
              :or,
              DataMapper::Query::Conditions::Comparison.new(:in, heffalump_model.properties[:the_color], []),
              DataMapper::Query::Conditions::Comparison.new(:in, heffalump_model.properties[:number_of_spots], [5])
            )
          ).should == [ @five ]
        end

        it 'should be able to search for objects not included in an array of values' do
          heffalump_model.all(:number_of_spots.not => [ 1, 3, 5, 7 ]).should be_include(@two)
        end

        it 'should be able to search for objects not included in an array of values' do
          heffalump_model.all(:number_of_spots.not => [ 1, 3, 5, 7 ]).should_not be_include(@five)
        end

        it 'should be able to search for objects not included in an inclusive range of values' do
          heffalump_model.all(:number_of_spots.not => 1..4).should be_include(@five)
        end

        it 'should be able to search for objects not included in an exclusive range of values' do
          heffalump_model.all(:number_of_spots.not => 1...5).should be_include(@five)
        end

        it 'should not be able to search for values not included in an inclusive range of values' do
          heffalump_model.all(:number_of_spots.not => 1..5).should_not be_include(@five)
        end

        it 'should not be able to search for values not included in an exclusive range of values' do
          heffalump_model.all(:number_of_spots.not => 1...6).should_not be_include(@five)
        end
      end
    end
  end
end