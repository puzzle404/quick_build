# frozen_string_literal: true

# Client-side tabbed panel primitive. Switching tabs happens via the
# qb--tabs Stimulus controller (no page reload, no Turbo navigation).
#
# Usage:
#   <%= render Qb::TabbedPanelComponent.new do |tp| %>
#     <% tp.with_tab(label: "Materiales", count: 0) do %>
#       ...panel html...
#     <% end %>
#     <% tp.with_tab(label: "Gastos", count: 3) do %>
#       ...panel html...
#     <% end %>
#   <% end %>
class Qb::TabbedPanelComponent < ViewComponent::Base
  Tab = Struct.new(:label, :count, :body, keyword_init: true)

  def initialize
    @tabs = []
  end

  # before_render triggers the caller's block (which calls with_tab) so that
  # @tabs is populated before the ERB template iterates over them.
  def before_render
    content
  end

  def with_tab(label:, count: nil, &block)
    @tabs << Tab.new(label: label, count: count, body: block)
  end

  def tabs
    @tabs
  end
end
