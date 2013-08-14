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
        
        def build_query(query_method, query)
          query_builder = @service.send(query_method)
          DataMapper.logger.debug("build_query starting with #{query_builder.inspect}")
          build_conditions(query_builder, query.conditions) if query.conditions
          build_order(query_builder, query.order) if query.order
          build_limit_and_offset(query_builder, query.limit, query.offset) if query.limit
          DataMapper.logger.debug("build_query ENDING with #{query_builder.inspect}")
        end
        
        private
        
        def build_conditions(query_builder, conditions)
          conditions.each do |condition|
            if condition.instance_of? ::DataMapper::Query::Conditions::EqualToComparison
              query_builder.filter("#{condition.subject.field} eq '#{condition.loaded_value}'")
            elsif condition.instance_of? ::DataMapper::Query::Conditions::InclusiveRange
              raise "BOOM"
            else
              raise "build_conditions #{condition.class} is not yet supported!"
            end
          end
        end
        
        def build_order(query_builder, order_by_array)
          order_by_array.each do |order|
            query_builder.order_by(order.target.field)
          end
        end
        
        def build_limit_and_offset(query_builder, limit, offset)
          query_builder.skip(offset).top(limit)
        end
      end
    end
  end
end