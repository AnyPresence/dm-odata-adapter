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
        
        #<DataMapper::Query @repository=:default @model=Heffalump @fields=[#<DataMapper::Property::Serial @model=Heffalump @name=:id>, #<DataMapper::Property::String @model=Heffalump @name=:color>, #<DataMapper::Property::Integer @model=Heffalump @name=:num_spots>, #<DataMapper::Property::Boolean @model=Heffalump @name=:striped>] @links=[] @conditions=#<DataMapper::Query::Conditions::AndOperation:0x007fcad3bc6830 @operands=
        #<Set: {#<DataMapper::Query::Conditions::InclusionComparison @subject=#<DataMapper::Property::Integer @model=Heffalump @name=:num_spots> @dumped_value=1..5 @loaded_value=1..5>}>> @order=[#<DataMapper::Query::Direction @target=#<DataMapper::Property::Serial @model=Heffalump @name=:id> @operator=:asc>] @limit=nil @offset=0 @reload=false @unique=false> 
        
        
       # @conditions=#<DataMapper::Query::Conditions::AndOperation:0x007f9ddaa28788 @operands=#<Set: {#<DataMapper::Query::Conditions::NotOperation:0x007f9ddaa28ad0 @operands=#<Set: {#<DataMapper::Query::Conditions::EqualToComparison @subject=#<DataMapper::Property::String @model=Heffalump @name=:color> @dumped_value="black" @loaded_value="black">}>, @parent=#<DataMapper::Query::Conditions::AndOperation:0x007f9ddaa28788 ...>>}>>
        def build_conditions(query_builder, conditions)
          conditions.each do |condition|
            build_condition(query_builder, condition)
          end
        end
        
        def build_condition(query_builder, condition)
          if condition.instance_of? ::DataMapper::Query::Conditions::EqualToComparison
            subject = condition.subject.field
            value = condition.loaded_value
            query_builder.filter("#{subject} eq #{value}")
          elsif condition.instance_of? ::DataMapper::Query::Conditions::InclusionComparison
            subject = condition.subject.field
            min = condition.loaded_value.min
            max = condition.loaded_value.max
            query_builder.filter("#{subject} ge #{min}").filter("#{subject} le #{max}")
          elsif condition.instance_of? ::DataMapper::Query::Conditions::NotOperation
            
          else
            raise "build_condition #{condition.class} is not yet supported!"
          end
        end
        
        def build_order(query_builder, order_by_array)
          order_by_array.each do |order|
            query_builder.order_by(order.target.field)
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