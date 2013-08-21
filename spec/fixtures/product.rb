class Product
  include ::DataMapper::Resource

#  property :id, Serial, field: 'ID'
  property :id, String, field: "ProductId", key: true
  property :weight_unit, String, field: "WeightUnit"
  property :weight_measure, Float, field: "WeightMeasure"
  property :measure_unit, String, field: "MeasureUnit"
  property :tax_tarif_code, Integer, field: "TaxTarifCode", :default => 1
  property :supplier_name, String, field: "SupplierName"
  property :supplier_id, String, field: "SupplierId"
  property :description, String, field: "Description"
  property :name, String, field: "Name"
  property :category, String, field: "Category"
  property :type_code, String, field: "TypeCode"
  property :price, Float, field: "Price"
  property :curreny_code, String, field: "CurrencyCode"
  property :width, Float, field: "Width"
  property :depth, Float, field: "Depth"
  property :height, Float, field: "Height"
  property :dim_unit, String, field: "DimUnit"
  property :product_picture_url, String, field: "ProductPicUrl"
end