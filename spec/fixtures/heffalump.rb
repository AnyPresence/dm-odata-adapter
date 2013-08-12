class Heffalump
  include ::DataMapper::Resource

  property :id, Serial, field: 'ID'
  property :color, String, field: 'COLOR'
  property :num_spots, Integer, field: 'NUM_SPOTS'
  property :striped, Boolean, field: 'STRIPED'
  
end
