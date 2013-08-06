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
            klass = Object.const_set(klass_name,Class.new)
	    klass.class_eval do
  	      attr_accessor *attributes

              define_method(:initialize) do |*values|
                attributes.each_with_index do |name,i|
                  instance_variable_set("@#{name}", values[i])
                end
              end
            end
          end
          klass.new(*hash.values)
        end

        def resource_from_remote(model, hash)
         DataMapper.logger.debug("resource_from_remote(#{model}, #{hash})")
        end

        private
        def build_class_name(model)
          "Remote::#{model}"        
	end
      end
    end
  end
end
