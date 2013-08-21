module DataMapper
  module Adapters
    module Odata
      class BaseBuilder
        include ::DataMapper::Inflector
        
        def initialize(odata_service)
          @odata_service = odata_service
        end
        
        ### Methods that must be implemented by subclasses follow:
        
        def build_create_method_name(storage_name)
          raise "Sub-classes must implement this method."
        end
        
        def build_collection_name(storage_name)
          raise "Sub-classes must implement this method."
        end
    
        def build_equal_check(subject, value)
          raise "Sub-classes must implement this method."
        end
        
        def build_null_check(subject)
          raise "Sub-classes must implement this method."
        end
        
        def quote(value)
          raise "Sub-classes must implement this method."
        end
        
        ### Common methods follow:
        
        def build_query_method_name(storage_name)
          build_collection_name(storage_name).to_sym
        end
        
        def build_query(query_builder, query)
          DataMapper.logger.debug("#{self.class.name} build_query starting with #{query_builder.inspect}")
          if query.conditions
            query_filter = ""
            filter_string = build_conditions(query_filter, query.conditions) 
            DataMapper.logger.debug("#{self.class.name} build_query built query_filter of #{query_filter}")
            query_builder.filter(query_filter) unless query_filter.empty?
          end
          build_order(query_builder, query.order) if query.order
          build_limit_and_offset(query_builder, query.limit, query.offset)
          DataMapper.logger.debug("#{self.class.name} build_query ENDING with #{query_builder.inspect}")
        end
        
        def build_conditions(query_string, conditions)
          conditions.each do |condition|
            build_condition(query_string, condition)
          end
        end
        
        def build_condition(query_string, condition)
          if condition.instance_of? ::DataMapper::Query::Conditions::AndOperation
            query_string << " and ( "
            build_conditions(query_string, condition.operands)
            query_string << " ) "
          elsif condition.instance_of? ::DataMapper::Query::Conditions::OrOperation
            array = condition.operands.to_a
            filters = array.collect do |operand|
              filter = ""
              build_condition(filter, operand)
              filter
            end
            query_string << filters.join(" or ")
          elsif condition.instance_of? ::DataMapper::Query::Conditions::EqualToComparison
            query_string << build_equal_check(condition.subject.field, condition.loaded_value)
          elsif condition.instance_of? ::DataMapper::Query::Conditions::InclusionComparison
            build_include_comparison(query_string, condition, condition.subject.field)
          elsif condition.instance_of? ::DataMapper::Query::Conditions::NotOperation
            query_string << " not ( "
            build_conditions(query_string, condition.operands)
            query_string << " ) "
          else
            raise "build_condition #{condition.class} is not yet supported!"
          end
        end
        
        def build_include_comparison(query_string, condition, subject)
          if (array = condition.loaded_value).instance_of? Array
            build_array_include_comparison(query_string, array, subject)
          elsif (range = condition.loaded_value).instance_of? Range
            build_range_include_comparison(query_string, range, subject)
          else
            raise "Unsupported query feature! #{condition.inspect}"
          end
        end
        
        def build_array_include_comparison(query_string, array, subject)
          if array.empty?
            raise "Unsupported query feature!" unless subject.instance_of? String
            query_string << build_null_check(subject)
          else
            ors = array.collect do |value|
              build_equal_check(subject, value)
            end
            query_string << " ( #{ors.join(' or ')} ) "
          end
        end
        
        def build_range_include_comparison(query_string, range, subject)
          query_string << " ( #{subject} ge #{quote(range.min)} and #{subject} le #{quote(range.max)} ) "
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