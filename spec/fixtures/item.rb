class Item
  include ::DataMapper::Resource

  property :id, Serial, field: 'Product'
  property :quantity, Integer, field: 'Quantity', required: true
  
end
