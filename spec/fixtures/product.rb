class Product
  include ::DataMapper::Resource

#  property :id, Serial, field: 'ID'
  property :id, String, field: "ID", key: true
  property :name, String, field: "Name"
  property :description, String, field: "Description"
  property :release_date, Date, field: "ReleaseDate", required: true
  property :discontinued_date, Date, field: "DiscontinuedDate"
  property :rating, Integer, field: "Rating"
  property :price, Float, field: "Price"
  property :category, String, field: "Category"
  property :supplier, String, field: "Supplier"
  
  def __metadata=(f)
    puts f
  end
end
