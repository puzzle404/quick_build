# frozen_string_literal: true

# The single chrome every drawer-hosted view renders inside the "drawer"
# turbo-frame: fixed header (eyebrow + title + optional subtitle + close),
# scrollable body (the block content), optional fixed footer. The outer
# backdrop/positioning shell lives once in layouts/constructor.html.erb
# (Task 5) — this component only renders what goes *inside* the frame, so
# swapping content between views never touches the shell.
class Qb::DrawerComponent < ViewComponent::Base
  renders_one :custom_header
  renders_one :footer

  SIZES = { md: "480px", lg: "560px", xl: "880px" }.freeze

  def initialize(eyebrow: nil, title: nil, subtitle: nil, size: :lg)
    @eyebrow = eyebrow
    @title = title
    @subtitle = subtitle
    @width = SIZES.fetch(size)
  end
end
