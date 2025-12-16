# Explicit requires for AI classes (workaround for autoload issues)
require_relative '../ai/client'
require_relative '../ai/prompts/base'
require_relative '../ai/prompts/blueprint_analyzer'
require_relative '../ai/parsers/measurement_parser'
require_relative '../ai/services/vision_processor'
require_relative '../ai/services/blueprint_analyzer'

class AnalyzeBlueprintJob < ApplicationJob
  queue_as :default
  
  # Retry configuration for transient failures
  retry_on StandardError, wait: :polynomially_longer, attempts: 3
  
  # Don't retry on certain errors
  # TODO: Re-enable after fixing autoload: discard_on AI::Parsers::MeasurementParser::ParseError
  
  def perform(blueprint_id, analysis_id, filter: nil)
    blueprint = Blueprint.find(blueprint_id)
    analysis = AiBlueprintAnalysis.find(analysis_id)
    
    Rails.logger.info("Starting AI analysis #{analysis_id} for blueprint #{blueprint_id} (filter: #{filter || 'none'})")
    
    # Pass the analysis to the constructor
    analyzer = AI::Services::BlueprintAnalyzer.new(blueprint, filter: filter, analysis: analysis)
    analyzer.analyze
    
    Rails.logger.info("Completed AI analysis #{analysis_id} for blueprint #{blueprint_id}")
    
    analysis
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("Blueprint #{blueprint_id} not found: #{e.message}")
    raise
  rescue => e
    Rails.logger.error("Failed to analyze blueprint #{blueprint_id}: #{e.message}")
    raise
  end
  
  private
  
  # Future: broadcast completion to user
  def broadcast_analysis_completed(analysis)
    # Turbo::StreamsChannel.broadcast_replace_to(
    #   "blueprint_#{analysis.blueprint_id}",
    #   target: "ai_analysis_status",
    #   partial: "blueprints/ai_analysis_status",
    #   locals: { analysis: analysis }
    # )
  end
end
