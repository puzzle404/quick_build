# frozen_string_literal: true

# Client-side tabbed panel primitive. Switching tabs happens via the
# qb--tabs Stimulus controller (no page reload, no Turbo navigation).
#
# Usage:
#   <%= render Qb::TabbedPanelComponent.new do |tp| %>
#     <% tp.with_tab(label: "Materiales", count: 0) do %>
#       ...panel html (ERB, nested components, etc.)...
#     <% end %>
#     <% tp.with_tab(label: "Gastos", count: 3) do %>
#       ...panel html...
#     <% end %>
#   <% end %>
#
# Each tab is a proper ViewComponent slot (renders_many), so the block content
# is captured into the slot's own buffer — NOT written inline to the caller's
# buffer. Using a raw Proc here would leak the panel markup out of place.
class Qb::TabbedPanelComponent < ViewComponent::Base
  renders_many :tabs, "TabSlotComponent"

  # Slot component: holds the tab's label/count and renders its block content
  # (the panel body) when output via `<%= tab %>`.
  class TabSlotComponent < ViewComponent::Base
    attr_reader :label, :count

    def initialize(label:, count: nil)
      @label = label
      @count = count
    end

    def call
      content
    end
  end
end
