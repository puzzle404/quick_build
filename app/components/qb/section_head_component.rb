# frozen_string_literal: true

# Section header used between content blocks: small caps mono title + optional
# subtitle and right-aligned action slot.
class Qb::SectionHeadComponent < ViewComponent::Base
  renders_one :right

  def initialize(title:, subtitle: nil)
    @title = title
    @subtitle = subtitle
  end

  attr_reader :title, :subtitle
end
