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

        def collection_from_remote(model, collection)
          DataMapper.logger.debug("resource_from_remote(#{model}, #{collection})")
          resources = []
          collection.each do |remote_instance|
            resources << resource_from_remote(model, remote_instance)
          end
          resources
        end
        
        def resource_from_remote(model,instance)
          DataMapper.logger.debug("resource_from_remote(#{model}, #{instance})")
          dm_hash = {}
          model.properties.each do |property|
            value = instance.send(property.field.to_sym)
            dm_hash[property] = property.typecast(value)
          end
          dm_hash
        end
        
        private
        
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
