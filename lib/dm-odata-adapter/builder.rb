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
          build_limit_and_offset(query_builder, query.limit, query.offset)
          DataMapper.logger.debug("build_query ENDING with #{query_builder.inspect}")
        end
        
        private
        
        def build_conditions(query_builder, conditions)
          conditions.each do |condition|
            build_condition(query_builder, condition)
          end
        end
        
        def build_condition(query_builder, condition, negated=false)
          if condition.instance_of? ::DataMapper::Query::Conditions::EqualToComparison
            subject = condition.subject.field
            value = condition.loaded_value
            query_builder.filter("#{subject} #{negated ? 'ne' : 'eq'} #{quote(value)}")
          elsif condition.instance_of? ::DataMapper::Query::Conditions::InclusionComparison
            subject = condition.subject.field
            min = condition.loaded_value.min
            max = condition.loaded_value.max
            query_builder.filter("#{subject} #{negated ? 'lt' : 'ge'} #{quote(min)}")
            query_builder.filter("#{subject} #{negated ? 'gt' : 'le'} #{quote(max)}")
          elsif condition.instance_of? ::DataMapper::Query::Conditions::NotOperation
            condition.operands.each do |operand|
              build_condition(query_builder,operand,true)
            end
          else
            raise "build_condition #{condition.class} is not yet supported!"
          end
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
        
        def build_order(query_builder, order_by_array)
          order_by_array.each do |order|
            query_builder.order_by("#{order.target.field} #{order.operator}")
          end
        end
        
        def build_limit_and_offset(query_builder, limit, offset)
          query_builder.skip(offset) if offset and offset > 0
          query_builder.top(limit) if limit and limit > 0
        end
      end
    end
  end
end