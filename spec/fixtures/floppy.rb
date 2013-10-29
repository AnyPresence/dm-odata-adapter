module V2
  class Floppy
    include ::DataMapper::Resource

    property :the_id , Serial, field: 'id'
    property :the_color, String, field: 'color'
    property :number_of_spots, Integer, field: 'num_spots'
    property :striping, Boolean, field: 'striped'
  
    storage_names[:default] = 'Heffalumps'
  end
end
