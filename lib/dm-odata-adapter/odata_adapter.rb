module DataMapper
  module Adapters
    class OdataAdapter < DataMapper::Adapters::AbstractAdapter
      include ::DataMapper::Inflector
      include ::DataMapper::Adapters::Odata::Transformer

      def initialize(name, options)
        super
        @options = options
        scheme = @options.fetch(:scheme)
        host = @options.fetch(:host)
        port = @options.fetch(:port,nil)
        host = "#{host}:#{port}" if port
        path = @options.fetch(:path)
        service_url = "#{scheme}://#{host}#{path}" 
	      username = @options.fetch(:username,nil)
        password = @options.fetch(:password,nil) if username
        json_type = @options.fetch(:json_type)
	      if username.nil? && password.nil?
          DataMapper.logger.debug("Connecting using #{service_url}")
          @service = OData::Service.new(service_url, :json_type => json_type)
        else
	        DataMapper.logger.debug("Connecting using #{service_url} as #{username} with a #{password.size} letter password")
          @service = OData::Service.new(service_url, :username => username, :password => password, :json_type => json_type)
        end
	      @processed_classes = Hash.new
      end

      # Persists one or many new resources
      #
      # @example
      #   adapter.create(collection)  # => 1
      #
      # Adapters provide specific implementation of this method
      #
      # @param [Enumerable<Resource>] resources
      #   The list of resources (model instances) to create
      #
      # @return [Integer]
      #   The number of records that were actually saved into the data-store
      #
      # @api semipublic  
      def create(resources)
        created = 0
        
        resources.each do |resource|
          model = resource.model
          serial = model.serial
          storage_name = model.storage_name(resource.repository)
          DataMapper.logger.debug("About to create #{model} backed by #{storage_name} using #{resource.attributes}")

          begin
            create_method_name = build_create_method_name(storage_name)
            DataMapper.logger.debug("Built create method name #{create_method_name}")
            the_properties = resource.attributes(key_on=:field)
            id = SecureRandom.hex
            the_properties[serial.field] = id
            DataMapper.logger.debug("Properties are #{the_properties.inspect}")
            instance = resource_to_remote(model, the_properties)
            DataMapper.logger.debug("Instance is #{instance.methods}")
            
            @service.send(create_method_name, instance)
            @service.save_changes
            serial.set(resource,id)
            created += 1
          rescue => e
            trace = e.backtrace.join("\n")
            DataMapper.logger.error("Failed to create resource: #{e.message}")  
            DataMapper.logger.error(trace)  
          end
        end
        
        created
      end
      
      # Reads one or many resources from a datastore
      #
      # @example
      #   adapter.read(query)  # => [ { 'name' => 'Dan Kubb' } ]
      #
      # Adapters provide specific implementation of this method
      #
      # @param [Query] query
      #   the query to match resources in the datastore
      #
      # @return [Enumerable<Hash>]
      #   an array of hashes to become resources
      #
      # @api semipublic
      def read(query)
        DataMapper.logger.debug("Read #{query.inspect} and its model is #{query.model.inspect}")
        model = query.model
        storage_name = model.storage_name(query.repository)
        records = []
        begin
          query_method = build_query_method_name(storage_name)
          DataMapper.logger.debug("Using query method #{query_method}")
          @service.send(query_method)
          records = @service.execute
          DataMapper.logger.debug("Records are #{records.inspect}")
        rescue => e
          trace = e.backtrace.join("\n")
          DataMapper.logger.error("Failed to query: #{e.message}")  
          DataMapper.logger.error(trace)
        end
        return records
      end

      private 
      
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
