# frozen_string_literal: true

# Mobile pill: 12px, rounded 999, 6 tones, optional mono/dense.
class Qb::Mobile::PillComponent < ViewComponent::Base
  TONES = %i[ok warn bad info accent muted].freeze

  def initialize(label = nil, tone: :muted, mono: false, dense: false)
    @label = label
    @tone = TONES.include?(tone&.to_sym) ? tone.to_sym : :muted
    @mono = mono
    @dense = dense
  end

  def call
    body = (@label.presence || content).to_s
    attrs = [%(class="m-pill"), %(data-tone="#{@tone}")]
    attrs << 'data-mono' if @mono
    attrs << 'data-dense' if @dense
    %(<span #{attrs.join(' ')}>#{body}</span>).html_safe
  end
end
