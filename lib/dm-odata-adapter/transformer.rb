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
        
        private 
        
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
