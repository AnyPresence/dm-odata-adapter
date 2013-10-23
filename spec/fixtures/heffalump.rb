class ::Heffalump
  include ::DataMapper::Resource

  property :id, Serial
  property :color, String
  property :num_spots, Integer
  property :striped, Boolean
  
end
