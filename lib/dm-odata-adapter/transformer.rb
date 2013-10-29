module Container
  # Holder module for generated conversion classes
end

module DataMapper
  module Adapters
    module Odata
      module Transformer
                
        def update_remote_instance(odata_instance, attributes)
          attributes.each do |property, value|
            odata_instance.send("#{property.field}=", value)
          end
        end
        
        def transform_dm_resource_to_odata_remote_class(the_resource, class_name)
          hash = to_odata_hash(the_resource)
          DataMapper.logger.debug("resource_to_remote(#{class_name}, #{hash})")
          the_fields = the_resource.model.properties.map { |p| p.field.to_sym }
          DataMapper.logger.debug("the_fields are #{the_fields.inspect}")
          
          if(@class_registry.has_key?(class_name))
            instance = @class_registry.fetch(class_name)
            DataMapper.logger.debug("FOUND #{class_name} in registry")
          else
            instance = create_odata_class(class_name, the_fields)
            @class_registry[class_name] = instance
            DataMapper.logger.debug("REGISTERED #{class_name} #{instance}")
          end
          
          instance.read_hash(hash)
          DataMapper.logger.debug("Returning instance #{instance.inspect}")
          instance
        end
        
        def update_resource(resource, remote_instance, serial)
          updated = 0
          model = resource.model
          @log.debug("update_resource(#{resource.inspect}, #{remote_instance.inspect}, #{serial.inspect})")
          if netweaver?
            if remote_instance == true # A failed create returns true for some reason
              @log.debug("Something went wrong while creating instance.")
            else remote_instance.first.__metadata.has_key?(:uri) # Actual success has metadata with a URI
              obj = object_from_remote(model,remote_instance)
              initialize_serial(resource, obj.send(serial.property))
              @log.debug("Created #{resource.inspect}")
              updated = 1
            end
          elsif microsoft?
            make_field_to_property_hash(model).each do |field, property|
              name = property.field
              next if (remote_value = remote_instance.send(name)).nil?
              value = property.typecast(remote_value)
              DataMapper.logger.debug("#{name} = #{value}")
              if property.instance_of? DataMapper::Property::Object
                raise "Array properties are not yet supported!"
              else
                property.set!(resource, value)
              end
            end
            updated = 1 unless serial.get(resource).nil?
          else
            raise "We should not get here"
          end
          @log.debug("updated #{updated}")
          updated
        end
        
        def collection_from_remote(model, array)
          DataMapper.logger.debug("collection_from_remote is about to parse\n #{array.inspect}")
          field_to_property = make_field_to_property_hash(model)
          array.collect do |remote_instance|
            record_from_remote(remote_instance, field_to_property)
          end
        end
        
        private 
        
        def to_odata_hash(the_resource)
          DataMapper.logger.debug("to_odata_hash(#{the_resource})")
          hash = the_resource.attributes(key_on = :field)
          hash['__metadata'] = the_resource.__metadata unless the_resource.__metadata.nil?
          DataMapper.logger.debug("to_odata_hash returning #{hash.inspect}")
          hash
        end

        def create_odata_class(class_name, the_fields)
          Container.const_set(class_name, Class.new {
            attr_accessor *the_fields

            define_method :read_hash do |hash|
              hash.each do |field, value|
                self.send "#{field}=", value
              end
            end
            
            define_method :to_s do
              "#{self.class} " + the_fields.collect do |field|
                "#{field}:#{self.send(field).to_s}"
              end.join(', ')
            end
            
          })
          DataMapper.logger.debug("Created new class #{class_name}")
          Container.const_get(class_name).new
        end
        
        def object_from_remote(model, remote_instance)
          DataMapper.logger.debug("object_from_remote is about to parse\n #{remote_instance.inspect}")
          field_to_property = make_field_to_property_hash(model)
          record_from_remote(remote_instance, field_to_property)
        end
          
        def microsoft?
          @service_type == :Default
        end
        
        def netweaver?
          @service_type == :Netweaver
        end
        
        def record_from_remote(instance, field_to_property)
          DataMapper.logger.debug("record_from_remote using:\n#{field_to_property}\nAnd #{instance.inspect}")
          record = {}
          field_to_property.each do |field, property|
            name = property.field
            next unless value = instance.send(name)
            DataMapper.logger.debug("#{name} = #{value}")
            if property.instance_of? DataMapper::Property::Object
              raise "Array properties are not yet supported!"
            else
              record[property.field] = property.typecast(value)
            end
          end
          DataMapper.logger.debug("record_from_remote returning #{record}")
          record
        end
        
        def make_field_to_property_hash(model)
          Hash[ model.properties(model.default_repository_name).map { |p| [ p.field, p ] } ]
        end
        
	      def to_ruby_odata_instance(instance, hash)
	        DataMapper.logger.debug("to_ruby_odata_instance called with #{instance.instance_variables} and #{hash.inspect}")
	        hash.each do |field, value|
	          DataMapper.logger.debug("Setting #{field} = #{value}")
            instance.send("#{field}=",value)
          end
          instance
        end
      end
    end
  end
end
