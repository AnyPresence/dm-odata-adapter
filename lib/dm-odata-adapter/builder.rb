module DataMapper
  module Adapters
    module Odata
      module Builder
        
        def build_create_method_name(storage_name)
          "AddTo#{collection_name(storage_name)}".to_sym
        end

        def build_query_method_name(storage_name)
          collection_name(storage_name).to_sym
        end

        def collection_name(storage_name)
          camelize(pluralize(storage_name.to_s))
        end
        
      end
    end
  end
end