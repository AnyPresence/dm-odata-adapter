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
      

      def build_create_method_name(storage_name)
        "AddTo#{camelize(pluralize(storage_name.to_s))}"
      end
    end
  end
end
