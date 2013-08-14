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
	          attributes = [*hash.keys.select{|k| k.to_sym}]
            klass = Container.const_set(klass_name.to_sym,Object.class)
	          klass.class_eval do
  	          attr_accessor *attributes
            end
            DataMapper.logger.debug("Caching new class for model #{model}")
            @processed_classes[klass_name] = klass
          else
            DataMapper.logger.debug("Cache has class for model #{model}")
          end
          instance = to_ruby_odata_instance(klass.new, hash)
          DataMapper.logger.debug("Returning instance #{instance.instance_variables}")
          instance
        end

        def collection_from_remote(model, array)
          DataMapper.logger.debug("collection_from_remote is about to parse\n #{array.inspect}")
          field_to_property = make_field_to_property_hash(model)
          array.collect do |remote_instance|
            record_from_remote(remote_instance, field_to_property)
          end
        end
        
        def record_from_remote(instance, field_to_property)
          DataMapper.logger.debug("record_from_remote using:\n#{field_to_property}\nAnd #{instance.inspect}")
          record = {}
          field_to_property.each do |field, property|
            name = property.name
            next unless value = instance.send(field.to_sym)
            DataMapper.logger.debug("#{field} = #{value}")
            if property.instance_of? DataMapper::Property::Object
              raise "Array properties are not yet supported!"
            else
              record[field] = property.typecast(value)
            end
          end
          record
        end
                
        private
        
        def make_field_to_property_hash(model)
          Hash[ model.properties(model.default_repository_name).map { |p| [ p.field, p ] } ]
        end
        
        def build_class_name(model)
          "#{model}"
	      end
	      
	      def to_ruby_odata_instance(instance, hash)
	        hash.each do |field, value|
	          DataMapper.logger.debug("Setting #{field} = #{value}")
            instance.send("#{field}=",value)
          end
          instance
        end
        
        def from_ruby_odata_instance(klass, hash)
          
        end
        
      end
    end
  end
end
