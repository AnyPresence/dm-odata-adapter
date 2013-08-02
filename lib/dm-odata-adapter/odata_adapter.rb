module DataMapper
  module Adapters
    class OdataAdapter < DataMapper::Adapters::AbstractAdapter
      
      def initialize(name, options)
        super
        @options = options
        scheme = @options.fetch(:scheme)
        host = @options.fetch(:host)
        port = @options.fetch(:port,nil)
        host = "#{host}:#{port}" if port
        path = @options.fetch(:path)
        service_url = "#{scheme}://#{host}#{path}" 
        DataMapper.logger.debug("Connecting using #{service_url}")
        @service = OData::Service.new(service_url)
        DataMapper.logger.debug("Initialized service to #{@service.inspect}")
      end
      
    end
  end
end