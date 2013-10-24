module Odata
  class QueryBuilder < OData::QueryBuilder
    
    def initialize(root, additional_params = {})
      DataMapper.logger.debug("--- initializing instance of query builder with #{root.inspect} and #{additional_params.inspect}")
      super
    end
       
  end
end

