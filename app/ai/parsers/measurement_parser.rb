module AI
  module Parsers
    class MeasurementParser
      class ParseError < StandardError; end
      
      def initialize(raw_response)
        @raw_response = raw_response
      end
      
      # Parse the LLM response into structured measurements
      # @return [Hash] parsed measurements in the format expected by the blueprint viewer
      def parse
        json_data = extract_json
        validate_structure!(json_data)
        
        {
          elements: parse_elements(json_data['elements']),
          scale_detected: json_data['scale_detected'],
          scale_notes: json_data['scale_notes'],
          general_notes: json_data['general_notes']
        }
      rescue JSON::ParserError => e
        raise ParseError, "Invalid JSON response: #{e.message}"
      end
      
      private
      
      def extract_json
        # Sometimes the LLM adds markdown code blocks, remove them
        cleaned = @raw_response.strip
        cleaned = cleaned.gsub(/^```json\n/, '').gsub(/\n```$/, '')
        
        JSON.parse(cleaned)
      end
      
      def validate_structure!(data)
        unless data.is_a?(Hash) && data.key?('elements')
          raise ParseError, "Response missing 'elements' key"
        end
        
        unless data['elements'].is_a?(Array)
          raise ParseError, "'elements' must be an array"
        end
      end
      
      def parse_elements(elements)
        elements.map do |element|
          {
            type: element['type'],
            construction_item: element['construction_item'],
            estimated_value: element['estimated_value'].to_f,
            unit: element['unit'],
            confidence: element['confidence'].to_i,
            description: element['description']
          }
        end
      end
    end
  end
end
