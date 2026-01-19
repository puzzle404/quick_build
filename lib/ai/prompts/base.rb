module Ai
  module Prompts
    class Base
      def build
        raise NotImplementedError, "Subclasses must implement #build"
      end
      
      protected
      
      def format_json_response_instruction
        <<~INST
          
          IMPORTANTE: Responde ÚNICAMENTE con JSON válido, sin texto adicional antes o después.
          El formato debe ser exactamente como se especifica.
        INST
      end
    end
  end
end
