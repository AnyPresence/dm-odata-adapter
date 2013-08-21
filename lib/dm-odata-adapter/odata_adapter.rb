module DataMapper
  module Adapters
    class OdataAdapter < DataMapper::Adapters::AbstractAdapter
      include ::DataMapper::Adapters::Odata::Transformer
      include ::DataMapper::Adapters::Odata::IdentityBroker
            
      def initialize(name, options)
        super
        level = 'debug'
        DataMapper::Logger.new($stdout,level)
        @log = DataMapper.logger
        if level == 'debug'
          @log.debug("Adding REST client debugging proxy")
          RestClient.log =  $stdout
        end
        @service_options = {}
        @options = options
        scheme = @options.fetch(:scheme)
        host = @options.fetch(:host)
        port = @options.fetch(:port,nil)
        host = "#{host}:#{port}" if port
        path = @options.fetch(:path)
        service_url = "#{scheme}://#{host}#{path}" 

	      username = @options.fetch(:username,nil)
	      if username
          password = @options.fetch(:password)
          @service_options[:username] = username
          @service_options[:password] = password
        end

        @service_options[:json_type] = @options.fetch(:json_type)
        
        service_type = @options.fetch(:builder, :Hana)
        @builder = "::DataMapper::Adapters::Odata::#{service_type}Builder".constantize.new
        @log.debug("Will use builder #{@builder}")
        
        if service_type == :Netweaver and @options.fetch(:enable_csrf_token,false)
          rest_options = {}
          token_header = :x_csrf_token
          rest_options[token_header] = "Fetch"
          if username
            auth = 'Basic ' + Base64.encode64("#{username}:#{password}").chomp
            rest_options['Authorization'] = auth
          end
          rest_options[:json_type] = @service_options[:json_type]
          @log.debug("Grabbing token_header with #{service_url} and #{rest_options}")
          response = RestClient.get service_url, rest_options
          @service_options[token_header] = response.headers.fetch(token_header)
          @log.debug("Response to token_header request was #{response.headers.inspect}")
          @log.debug("Will use CSRF token #{@service_options[token_header]}")
        end
        
        @log.debug("Connecting using #{service_url}")
        @service = OData::Service.new(service_url, @service_options)
        
	      @processed_classes = Hash.new
        @id_seed = 0
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
          @log.debug("About to create #{model} backed by #{storage_name} using #{resource.attributes}")

          begin
            create_method_name = @builder.build_create_method_name(storage_name)
            @log.debug("Built create method name #{create_method_name}")
            the_properties = resource.attributes(key_on=:field)
            id = generate_unique_id(resource)
            the_properties[serial.field] = id
            @log.debug("Properties are #{the_properties.inspect}")
            instance = resource_to_remote(model, the_properties)
            @service.send(create_method_name, instance)
            remote_instance = @service.save_changes
            @log.debug("Remote instance saved_changes returned is #{remote_instance.inspect}")

            if remote_instance == true # A failed create returns true for some reason
              @log.debug("Something went wrong while creating instance.")
            else remote_instance.first.__metadata.has_key?(:uri) # Actual success has metadata with a URI
              initialize_serial(resource, id)
              @log.debug("Created #{resource.inspect}")
              created += 1
            end
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
        @log.debug("Read #{query.inspect} and its model is #{query.model.inspect}")
        model = query.model
        storage_name = model.storage_name(query.repository)
        records = []
        begin
          query_method = @builder.build_query_method_name(storage_name)
          @log.debug("Using query method #{query_method}")
          query_builder = @service.send(query_method)
          @builder.build_query(query_builder, query)
          odata_collection = @service.execute
          records = collection_from_remote(model,odata_collection)
          @log.debug("Records are #{records.inspect}")
        rescue => e
          trace = e.backtrace.join("\n")
          DataMapper.logger.error("Failed to query: #{e.message}")  
          DataMapper.logger.error(trace)
        end
        return records
      end

      # Updates one or many existing resources
      #
      # @example
      #   adapter.update(attributes, collection)  # => 1
      #
      # Adapters provide specific implementation of this method
      #
      # @param [Hash(Property => Object)] attributes
      #   hash of attribute values to set, keyed by Property
      # @param [Collection] collection
      #   collection of records to be updated
      #
      # @return [Integer]
      #   the number of records updated
      #
      # @api semipublic
      def update(attributes, collection)
        updated = 0
        @log.debug("Update called with:\nAttributes #{attributes.inspect} \nCollection: #{collection.inspect}")
        collection.select do |resource|
          model = resource.model
          serial = model.serial
          query_method = @builder.build_query_method_name(model.storage_name(resource.repository))
          id = serial.get(resource)
          @log.debug("About to query with ID #{id}")
          @service.send(query_method, id)
          odata_instance = @service.execute.first
          @log.debug("About to call update on #{odata_instance}")
          odata_instance = update_remote_instance(odata_instance, attributes)
          @service.update_object(odata_instance)
          @log.debug("About to save #{odata_instance}")
          result = @service.save_changes
          
          @log.debug("Result of update call #{result}")
          if result
            updated += 1
            attributes.each do |property, value|
              property.set!(resource, property.typecast(value))
            end
          else
            DataMapper.logger.error("Updating #{resource} failed")
          end
          
        end
        updated
      end
      
      # Deletes one or many existing resources
      #
      # @example
      #   adapter.delete(collection)  # => 1
      #
      # Adapters provide specific implementation of this method
      #
      # @param [Collection] collection
      #   collection of records to be deleted
      #
      # @return [Integer]
      #   the number of records deleted
      #
      # @api semipublic
      def delete(collection)
        @log.debug("Delete called with: #{collection.inspect}")
        deleted = 0
         
        collection.each do |resource|
          model = resource.model
          serial = model.serial
          query_method = @builder.build_query_method_name(model.storage_name(resource.repository))
          id = serial.get(resource)
          
          begin
            @log.debug("About to query with ID #{id}")
            @service.send(query_method, id)
            odata_instance = @service.execute.first
            @log.debug("About to call delete on #{odata_instance}")

            @service.delete_object(odata_instance)
            result = @service.save_changes
            @log.debug("Result of delete is #{result}")
            deleted += 1 if result
          rescue => e
            DataMapper.logger.error("Failure while deleting #{e.inspect}")
          end
        end
        @log.debug("Deleted #{deleted} instances")
        deleted
      end
      
    end
  end
end
