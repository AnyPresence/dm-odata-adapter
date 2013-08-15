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
    
    it 'should not set the identity field for the resource if validation fails' do
      heffalump = Heffalump.new(:num_spots => 3)
      heffalump.save
      heffalump.id.should be_nil
    end
  end
  
  describe '#read' do
    before :all do
      @heffalump = Heffalump.create(:color => 'brownish hue')
    end

    it 'should not raise any errors' do
      lambda {
        Heffalump.all()
      }.should_not raise_error
    end

    it 'should return stuff' do
      Heffalump.all.should be_include(@heffalump)
    end
  end
  
  describe '#update' do
    before do
      @heffalump = Heffalump.create!(:color => 'indigo')
    end

    it 'should not raise any errors' do
      lambda {
        @heffalump.id.should_not be_nil
        @heffalump.color = 'violet'
        @heffalump.save
      }.should_not raise_error
    end

    it 'should not alter the identity field' do
      id = @heffalump.id
      @heffalump.color = 'violet'
      @heffalump.save
      @heffalump.id.should == id
    end

    it 'should update altered fields' do
      @heffalump.color = 'violet'
      @heffalump.save
      Heffalump.get(*@heffalump.key).color.should == 'violet'
    end

    it 'should not alter other fields' do
      color = @heffalump.color
      @heffalump.num_spots = 3
      @heffalump.save
      Heffalump.get(*@heffalump.key).color.should == color
    end
  end
  
  describe '#delete' do
    before do
      @heffalump = Heffalump.create(:color => 'forest green')
    end

    it 'should not raise any errors' do
      lambda {
        @heffalump.destroy
      }.should_not raise_error
    end

    it 'should delete the requested resource' do
      id = @heffalump.id
      @heffalump.destroy
      Heffalump.get(id).should be_nil
    end
  end   

  describe 'query matching' do
    before :all do
      @red  = Heffalump.create(:color => 'red')
      @two  = Heffalump.create(:color => 'rouge', :num_spots => 2)
      @five = Heffalump.create(:color => 'noir', :num_spots => 5)
    end

    describe 'conditions' do
      describe 'eql' do
        it 'should be able to search for objects included in an inclusive range of values' do
          Heffalump.all(:num_spots => 1..5).should be_include(@five)
        end

        it 'should be able to search for objects included in an exclusive range of values' do
          Heffalump.all(:num_spots => 1...6).should be_include(@five)
        end

        it 'should not be able to search for values not included in an inclusive range of values' do
          Heffalump.all(:num_spots => 1..4).should_not be_include(@five)
        end

        it 'should not be able to search for values not included in an exclusive range of values' do
          Heffalump.all(:num_spots => 1...5).should_not be_include(@five)
        end
      end
    end
  end      
end