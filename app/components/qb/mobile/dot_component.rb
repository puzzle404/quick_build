# frozen_string_literal: true

# 8×8 status dot with soft glow ring.
class Qb::Mobile::DotComponent < ViewComponent::Base
  TONES = %i[ok warn bad info accent muted].freeze

  def initialize(tone: :ok)
    @tone = TONES.include?(tone&.to_sym) ? tone.to_sym : :muted
  end

  def call
    %(<span class="m-dot" data-tone="#{@tone}"></span>).html_safe
  end
end
