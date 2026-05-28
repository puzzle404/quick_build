class AiBlueprintAnalysis < ApplicationRecord
  belongs_to :blueprint
  
  # Status values: queued, processing, completed, failed
  validates :status, presence: true, inclusion: { in: %w[queued processing completed failed] }
  validates :blueprint, presence: true
  
  # Scopes
  scope :pending, -> { where(status: ['queued', 'processing']) }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :applied, -> { where.not(applied_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  
  # State transitions
  def mark_as_processing!
    update!(status: 'processing')
  end
  
  def mark_as_completed!(response:, measurements:)
    update!(
      status: 'completed',
      raw_response: response,
      suggested_measurements: measurements
    )
  end
  
  def mark_as_failed!(error)
    update!(
      status: 'failed',
      error_message: error.message
    )
  end
  
  def mark_as_applied!
    update!(applied_at: Time.current)
  end
  
  # Helpers
  def processing?
    status == 'processing'
  end
  
  def completed?
    status == 'completed'
  end
  
  def failed?
    status == 'failed'
  end
  
  def applied?
    applied_at.present?
  end
  
  def suggested_count
    return 0 unless suggested_measurements.present?
    
    # Handle case where suggested_measurements is a String (shouldn't happen but defensive)
    measurements = if suggested_measurements.is_a?(String)
                     begin
                       JSON.parse(suggested_measurements)
                     rescue JSON::ParserError
                       {}
                     end
                   else
                     suggested_measurements
                   end
    
    measurements&.dig('elements')&.count || 0
  end
  
  # Safe accessor for suggested_measurements as Hash
  def safe_measurements
    return {} unless suggested_measurements.present?
    
    if suggested_measurements.is_a?(String)
      begin
        JSON.parse(suggested_measurements)
      rescue JSON::ParserError
        {}
      end
    else
      suggested_measurements || {}
    end
  end
end
