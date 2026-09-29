module Ai
  module Services
    class BlueprintAnalyzer
      attr_reader :analysis, :blueprint
      
      def initialize(blueprint, filter: nil, analysis: nil)
        @blueprint = blueprint
        @filter = filter
        @analysis = analysis
      end
      
      # Perform the complete analysis workflow
      # @return [AiBlueprintAnalysis] the completed analysis record
      def analyze
        # Create analysis if not provided
        @analysis ||= create_analysis_record
        
        begin
          @analysis.mark_as_processing!
          
          # Step 1: Process image with Vision API
          raw_response = process_vision
          
          # Step 2: Parse response into structured data
          parsed_measurements = parse_response(raw_response)
          
          # Step 3: Save results
          @analysis.mark_as_completed!(
            response: raw_response,
            measurements: parsed_measurements
          )
          
          Rails.logger.info("Successfully analyzed blueprint #{@blueprint.id}")
          @analysis
          
        rescue => e
          Rails.logger.error("Error analyzing blueprint #{@blueprint.id}: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
          
          @analysis.mark_as_failed!(e)
          raise
        end
      end
      
      private
      
      def create_analysis_record
        @analysis = AiBlueprintAnalysis.create!(
          blueprint: @blueprint,
          status: 'queued'
        )
      end
      
      def process_vision
        processor = VisionProcessor.new(@blueprint)
        processor.process(filter: @filter)
      end
      
      def parse_response(raw_response)
        parser = Ai::Parsers::MeasurementParser.new(raw_response)
        parser.parse
      end
    end
  end
end
