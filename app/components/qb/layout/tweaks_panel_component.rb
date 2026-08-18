# frozen_string_literal: true

# Floating panel that lets the user pick theme/density/layout. Persistence is
# handled by the qb--tweaks Stimulus controller (localStorage).
class Qb::Layout::TweaksPanelComponent < ViewComponent::Base
  THEMES   = [['graphite', 'Graphite'], ['night', 'Night']].freeze
  DENSITY  = [['compact', 'Compacta'], ['cozy', 'Cozy'], ['relaxed', 'Relajada']].freeze
  LAYOUTS  = [['sidebar', 'Sidebar'], ['toprail', 'Top rail']].freeze
end
