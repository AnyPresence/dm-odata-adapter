module DataMapper
  module Adapters
    module Odata
      class NetweaverBuilder < BaseBuilder
        
        def build_create_method_name(storage_name)
          build_collection_name(storage_name).to_sym
        end

        def build_collection_name(storage_name)
          camelize("#{singularize(storage_name.to_s)}Collection")
        end
        
        def build_equal_check(subject, value)
          "#{subject} eq #{quote(value)}"
        end
        
        def build_null_check(subject)
          "#{subject} eq null"
        end
          
        def quote(value)
          if value.nil?
            return "null"
          elsif value.instance_of? String
            return "'#{value}'"
          else
            return value
          end
        end
      end
    end
  end
end