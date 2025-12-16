module AI
  module Services
    class VisionProcessor
      def initialize(blueprint, client: AI::Client.new)
        @blueprint = blueprint
        @client = client
      end
      
      # Process the blueprint image and get AI analysis
      # @param filter [String, nil] optional filter (e.g., 'muros', 'aberturas')
      # @return [String] raw response from the LLM
      def process(filter: nil)
        image_url = build_image_url
        prompt = build_prompt(filter: filter)
        
        Rails.logger.info("Processing blueprint #{@blueprint.id} with AI (filter: #{filter || 'none'})")
        
        @client.analyze_image(
          image_url: image_url,
          prompt: prompt,
          max_tokens: 2000
        )
      end
      
      private
      
      def build_image_url
        # Get the public URL for the blueprint image
        # Cloudinary provides direct URLs
        if @blueprint.file.attached?
          # For Cloudinary/Active Storage, get the URL
          url = @blueprint.file.url
          
          # Ensure it's an absolute URL
          unless url.start_with?('http')
            # If it's a relative URL, prepend the host
            url = "#{ENV.fetch('APP_URL', 'http://localhost:3000')}#{url}"
          end
          
          url
        else
          raise "Blueprint #{@blueprint.id} has no attached file"
        end
      end
      
      def build_prompt(filter:)
        AI::Prompts::BlueprintAnalyzer.new(
          filter: filter,
          scale_known: @blueprint.scale_ratio.present?
        ).build
      end
    end
  end
end
