class Department
  include ::DataMapper::Resource

  property :id, Serial, :field => 'DepartmentId'
  property :name, String, :field => 'Name'
  property :group_name, String, :field => 'GroupName'
  property :modified_date, Date, :field => 'ModifiedDate'
  
end
