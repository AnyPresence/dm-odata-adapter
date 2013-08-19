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
          if query.conditions
            query_filter = ""
            filter_string = build_conditions(query_filter, query.conditions) 
            DataMapper.logger.debug("build_query built query_filter of #{query_filter}")
            query_builder.filter(query_filter) unless query_filter.empty?
          end
          build_order(query_builder, query.order) if query.order
          build_limit_and_offset(query_builder, query.limit, query.offset)
          DataMapper.logger.debug("build_query ENDING with #{query_builder.inspect}")
        end
        
        private
# @conditions=#<DataMapper::Query::Conditions::AndOperation:0x007fa52e2339c8 @operands=#<Set: {#<DataMapper::Query::Conditions::OrOperation:0x007fa52e22a620 @operands=#<Set: {#<DataMapper::Query::Conditions::InclusionComparison @subject=#<DataMapper::Property::String @model=Heffalump @name=:color> @dumped_value=[] @loaded_value=[]>, #<DataMapper::Query::Conditions::InclusionComparison @subject=#<DataMapper::Property::Integer @model=Heffalump @name=:num_spots> @dumped_value=[5] @loaded_value=[5]>}>, @parent=#<DataMapper::Query::Conditions::AndOperation:0x007fa52e2339c8 ...>>}>> @order=[#<DataMapper::Query::Direction @target=#<DataMapper::Property::Serial @model=Heffalump @name=:id> @operator=:asc>] @limit=nil @offset=0 @reload=false @unique=false>        
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
            subject = condition.subject.field
            value = condition.loaded_value
            query_string << "#{subject} eq #{quote(value)}"
          elsif condition.instance_of? ::DataMapper::Query::Conditions::InclusionComparison
            subject = condition.subject.field
            if (array = condition.loaded_value).instance_of? Array
              if array.empty?
                raise "Unsupported query feature!" unless subject.instance_of? String
                query_string << "length(#{subject}) eq 0 "
              else
                ors = array.collect do |value|
                  "#{subject} eq #{quote(value)}"
                end
                query_string << " ( #{ors.join(' or ')} ) "
              end
            elsif (range = condition.loaded_value).instance_of? Range
              query_string << " ( #{subject} ge #{quote(range.min)} and #{subject} le #{quote(range.max)} ) "
            else
              raise "Unsupported query feature! #{condition.inspect}"
            end
          elsif condition.instance_of? ::DataMapper::Query::Conditions::NotOperation
            query_string << " not ( "
            build_conditions(query_string, condition.operands)
            query_string << " ) "
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