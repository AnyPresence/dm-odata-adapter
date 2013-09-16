module DataMapper
  module Adapters
    module Odata
      class DefaultBuilder < BaseBuilder
        
        def build_create_method_name(storage_name)
          "AddTo#{build_collection_name(storage_name)}".to_sym
        end

        def build_collection_name(storage_name)
          camelize(pluralize(storage_name.to_s))
        end
        
        def build_equal_check(subject, value)
          if value.nil?
            build_null_check(subject)
          else
            "#{subject} eq #{quote(value)}"
          end
        end
        
        def build_null_check(subject)
          if subject.instance_of? DataMapper::Property::String
            "#{subject} eq null "
          else
            raise "Null checks are supported on String properties only."
          end
        end
          
        def quote(value)
          if value.instance_of? String
            return "'#{value}'"
          else
            return value
          end
        end
        
      end
    end
  end
end