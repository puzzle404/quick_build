# frozen_string_literal: true

# Mono-uppercase section eyebrow + body container.
class Qb::Mobile::SectionComponent < ViewComponent::Base
  renders_one :action

  def initialize(title: nil, padded: true)
    @title = title
    @padded = padded
  end
end
