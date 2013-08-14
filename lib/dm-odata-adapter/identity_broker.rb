module DataMapper
  module Adapters
    module Odata
      module IdentityBroker
        
        # This is needed until HANA supports auto generated serials
        class Serial
          attr_accessor :CLASS, :SEQUENCE_VALUE
          
          def initialize(class_name,sequence_value)
            @CLASS = class_name
            @SEQUENCE_VALUE = sequence_value
          end
        end
        
        def generate_unique_id(class_name)
          new_id = nil
          DataMapper.logger.debug("generate_unique_id(#{class_name})")
          @service.Serials
          sequences = @service.execute
          DataMapper.logger.debug("Sequences are #{sequences}")
          if sequences.empty?
            sequence = create_serial(class_name)
            new_id = sequence.SEQUENCE_VALUE
          else
            existing_sequence = sequences.select{|s| s.CLASS == class_name }.first
            if existing_sequence.nil?
              DataMapper.logger.debug("Sequence for #{class_name} doesn't exist.")
              sequence = create_serial(class_name)
              new_id = sequence.SEQUENCE_VALUE
            else
              DataMapper.logger.debug("Found sequence #{existing_sequence}")
              new_id = (existing_sequence.SEQUENCE_VALUE += 1)
              @service.update_object(existing_sequence)
              result = @service.save_changes
              raise "Error obtaining new sequence value for #{class_name}!" unless result 
            end
          end
          DataMapper.logger.debug("generate_unique_id returning #{new_id}")
          new_id
        end
        
        private
        
        def create_serial(class_name)
          serial = Serial.new(class_name,0)
          @service.AddToSerials(serial)
          instance = @service.save_changes
          DataMapper.logger.debug("Created sequence #{instance}")
          raise "Error creating new sequence entry for #{class_name}!" if instance == true
          serial
        end
        
      end
    end
  end
end