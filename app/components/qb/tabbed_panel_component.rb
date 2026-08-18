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

  # `active:` matches a tab's `key:` (ej: :notas) para abrir el panel en ese
  # tab en vez del primero — así una acción hecha en un tab (agregar nota,
  # gasto, foto…) puede volver mostrando ese mismo tab. Sin match, o sin
  # `active:`, cae al primer tab (comportamiento de siempre).
  def initialize(active: nil)
    @active = active
  end

  def active_index
    return 0 if @active.nil?

    tabs.index { |tab| tab.key == @active } || 0
  end

  # Slot component: holds the tab's label/count/key and renders its block
  # content (the panel body) when output via `<%= tab %>`.
  class TabSlotComponent < ViewComponent::Base
    attr_reader :label, :count, :key

    def initialize(label:, count: nil, key: nil)
      @label = label
      @count = count
      @key = key
    end

    def call
      content
    end
  end
end
