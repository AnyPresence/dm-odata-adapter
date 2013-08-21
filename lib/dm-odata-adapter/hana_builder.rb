module DataMapper
  module Adapters
    module Odata
      class HanaBuilder < BaseBuilder
        
        def build_create_method_name(storage_name)
          "AddTo#{build_collection_name(storage_name)}".to_sym
        end

        def build_collection_name(storage_name)
          camelize(pluralize(storage_name.to_s))
        end
        
        def build_equal_check(subject, value)
          "#{subject} eq #{quote(value)}"
        end
        
        def build_null_check(subject)
          "length(#{subject}) eq 0 "
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