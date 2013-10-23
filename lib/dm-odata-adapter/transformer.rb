module Container
  # Holder module for generated conversion classes
end

module DataMapper
  module Adapters
    module Odata
      module Transformer
                
        def resource_to_remote(model, hash)
          DataMapper.logger.debug("resource_to_remote(#{model}, #{hash})")
          klass_name = build_class_name(model)
          klass = @processed_classes[klass_name]
          if klass.nil?
            all_properties = make_field_to_property_hash(model)
	          attributes = [*all_properties.keys.select{|k| k.to_sym}]
            klass = Container.const_set(klass_name.to_sym,Object.class)
	          klass.class_eval do
  	          attr_accessor *attributes
            end
            DataMapper.logger.debug("Caching new class for model #{model}")
            @processed_classes[klass_name] = klass.new
          else
            DataMapper.logger.debug("Cache has instance for model #{model}")
          end
          instance = to_ruby_odata_instance(Container.const_get(klass_name).new, hash)
          DataMapper.logger.debug("Returning instance #{instance.instance_variables}")
          instance
        end
        
        def update_remote_instance(remote_instance, hash)
          DataMapper.logger.debug("fill_remote_instance is about to update \nInstance: #{remote_instance}\nWith: #{hash.inspect}")
          hash.each do |property, value|
	          DataMapper.logger.debug("Updating #{property.field} = #{value}")
            remote_instance.send("#{property.field}=", property.typecast(value))
          end
          remote_instance
        end
        
        def collection_from_remote(model, array)
          DataMapper.logger.debug("collection_from_remote is about to parse\n #{array.inspect}")
          field_to_property = make_field_to_property_hash(model)
          array.collect do |remote_instance|
            record_from_remote(remote_instance, field_to_property)
          end
        end
        
        def update_resource(resource, remote_instance, serial)
          created = 0
          model = resource.model
          @log.debug("update_resource(#{resource}, #{remote_instance}, #{serial})")
          if netweaver?
            if remote_instance == true # A failed create returns true for some reason
              @log.debug("Something went wrong while creating instance.")
            else remote_instance.first.__metadata.has_key?(:uri) # Actual success has metadata with a URI
              obj = object_from_remote(model,remote_instance)
              initialize_serial(resource, obj.send(serial.property))
              @log.debug("Created #{resource.inspect}")
              created = 1
            end
          elsif microsoft?
            obj = object_from_remote(model,remote_instance)
            make_field_to_property_hash(model).each do |field, property|
              name = property.field
              next unless value = obj[name]
              DataMapper.logger.debug("#{name} = #{value}")
              if property.instance_of? DataMapper::Property::Object
                raise "Array properties are not yet supported!"
              else
                property.set!(resource,value)
              end
            end
            created = 1 unless serial.get(resource).nil?
          else
            raise "We should not get here"
          end
          created
        end
        
        private 
        
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
            name = property.name
            next unless value = instance.send(name)
            DataMapper.logger.debug("#{name} = #{value}")
            if property.instance_of? DataMapper::Property::Object
              raise "Array properties are not yet supported!"
            else
              record[name] = property.typecast(value)
            end
          end
          DataMapper.logger.debug("record_from_remote returning #{record}")
          record
        end
        
        def make_field_to_property_hash(model)
          Hash[ model.properties(model.default_repository_name).map { |p| [ p.field, p ] } ]
        end
        
        def build_class_name(model)
          "#{model}"
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
