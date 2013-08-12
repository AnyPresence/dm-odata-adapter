module Container
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
          instance = klass.new
          hash.each do |field, value|
            instance.send("#{field}=",value)
          end
          DataMapper.logger.debug("Returning instance #{instance.instance_variables}")
          instance
        end

        def resource_from_remote(model, hash)
         DataMapper.logger.debug("resource_from_remote(#{model}, #{hash})")
        end

        private
        def build_class_name(model)
          "#{model}"
	      end
      end
    end
  end
end
