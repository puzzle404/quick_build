module Ai
  class Client
    def initialize
      @client = OpenAI::Client.new(
        access_token: ENV.fetch('OPENAI_API_KEY'),
        log_errors: true
      )
    end
    
    # Analyze blueprint image using GPT-4o-mini Vision
    # @param image_url [String] publicly accessible URL of the blueprint image
    # @param prompt [String] analysis prompt
    # @param max_tokens [Integer] maximum tokens for response (default: 1500)
    # @return [String] raw response from the model
    def analyze_image(image_url:, prompt:, max_tokens: 1500)
      response = @client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            {
              role: "user",
              content: [
                { type: "text", text: prompt },
                { type: "image_url", image_url: { url: image_url } }
              ]
            }
          ],
          max_tokens: max_tokens,
          temperature: 0.1 # Low temperature for consistent, factual responses
        }
      )
      
      response.dig("choices", 0, "message", "content")
    rescue => e
      Rails.logger.error("OpenAI API error: #{e.message}")
      raise
    end
    
    # Get approximate cost for an analysis
    # Based on GPT-4o-mini pricing: $0.150/1M input tokens, $0.600/1M output tokens
    def estimate_cost(input_tokens: 1000, output_tokens: 500)
      input_cost = (input_tokens / 1_000_000.0) * 0.150
      output_cost = (output_tokens / 1_000_000.0) * 0.600
      (input_cost + output_cost).round(4)
    end
  end
end
