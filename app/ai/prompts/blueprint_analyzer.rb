module AI
  module Prompts
    class BlueprintAnalyzer < Base
      def initialize(filter: nil, scale_known: false)
        @filter = filter
        @scale_known = scale_known
      end
      
      def build
        <<~PROMPT
          Eres un experto en análisis de planos de construcción arquitectónicos.
          Analiza cuidadosamente esta imagen de un plano y extrae información sobre elementos constructivos.
          
          #{filter_instruction}
          
          #{scale_instruction}
          
          Para cada elemento detectado, proporciona:
          1. Tipo de medición (line para longitudes, polygon para áreas, marker para puntos/cantidades)
          2. Nombre del elemento constructivo (ej: "Muro Ladrillo Hueco 12", "Abertura 0.80x2.00")
          3. Valor estimado numérico de la medición
          4. Unidad (m para metros lineales, m2 para metros cuadrados, un para unidades)
          5. Nivel de confianza en porcentaje (0-100)
          6. Descripción breve de ubicación o características
          
          Responde en el siguiente formato JSON:
          {
            "elements": [
              {
                "type": "line|polygon|marker",
                "construction_item": "Nombre descriptivo del elemento",
                "estimated_value": 15.5,
                "unit": "m|m2|un",
                "confidence": 85,
                "description": "Breve descripción de ubicación"
              }
            ],
            "scale_detected": true,
            "scale_notes": "Información sobre la escala si fue detectada",
            "general_notes": "Observaciones generales sobre el plano"
          }
          
          #{format_json_response_instruction}
          
          ENFÓCATE EN: Precisión en las mediciones, identificación correcta de elementos, y alta confianza en los datos proporcionados.
        PROMPT
      end
      
      private
      
      def filter_instruction
        return "" unless @filter
        
        filters_map = {
          "muros" => "SOLO muros y paredes",
          "aberturas" => "SOLO aberturas (puertas y ventanas)",
          "pisos_losas" => "SOLO pisos y losas (superficies horizontales)"
        }
        
        filter_text = filters_map[@filter] || @filter
        "IMPORTANTE: Analiza y extrae información ÚNICAMENTE de: #{filter_text}. Ignora todos los demás elementos.\n"
      end
      
      def scale_instruction
        if @scale_known
          "El plano ya tiene una escala definida. Usa esa escala para tus estimaciones."
        else
          "Intenta detectar la escala del plano (busca indicadores como '1:100', '1:50', etc.)."
        end
      end
    end
  end
end
