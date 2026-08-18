# frozen_string_literal: true

# Mobile-flavoured icon set (22px default, 24x24 viewBox, stroke 1.8).
# Mirrors `MIcon` from the handoff (components.jsx); a few names overlap with
# the desktop `Qb::IconComponent` but pose/size differ enough to keep them
# distinct.
class Qb::Mobile::IconComponent < ViewComponent::Base
  ICONS = {
    home:         %(<path d="M3 11.5L12 4l9 7.5"/><path d="M5 10.5V20h14v-9.5"/>),
    projects:     %(<path d="M3 7h6l2 2h10v11H3z"/>),
    search:       %(<circle cx="11" cy="11" r="7"/><path d="M20 20l-4-4"/>),
    library:      %(<path d="M4 4h6v16H4zM14 4h6v16h-6z"/><path d="M4 9h6M14 9h6"/>),
    user:         %(<circle cx="12" cy="8" r="3.5"/><path d="M4 20c0-4 3.5-6 8-6s8 2 8 6"/>),
    plus:         %(<path d="M12 5v14M5 12h14"/>),
    check:        %(<path d="M5 13l4 4 10-10"/>),
    'chev-right': %(<path d="M9 5l7 7-7 7"/>),
    'chev-down':  %(<path d="M5 9l7 7 7-7"/>),
    'chev-left':  %(<path d="M15 19l-7-7 7-7"/>),
    'arrow-right':%(<path d="M5 12h14M13 5l7 7-7 7"/>),
    'arrow-up':   %(<path d="M12 19V5M6 11l6-6 6 6"/>),
    'arrow-down': %(<path d="M12 5v14M6 13l6 6 6-6"/>),
    filter:       %(<path d="M4 6h16l-6 8v5l-4-1v-4z"/>),
    bell:         %(<path d="M6 8a6 6 0 1112 0c0 7 3 8 3 8H3s3-1 3-8"/><path d="M10 20a2 2 0 004 0"/>),
    cog:          %(<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 00.3 1.8l.1.1a2 2 0 11-2.8 2.8l-.1-.1a1.7 1.7 0 00-1.8-.3 1.7 1.7 0 00-1 1.5V21a2 2 0 11-4 0v-.1a1.7 1.7 0 00-1-1.5 1.7 1.7 0 00-1.8.3l-.1.1a2 2 0 11-2.8-2.8l.1-.1a1.7 1.7 0 00.3-1.8 1.7 1.7 0 00-1.5-1H3a2 2 0 110-4h.1a1.7 1.7 0 001.5-1 1.7 1.7 0 00-.3-1.8l-.1-.1a2 2 0 112.8-2.8l.1.1a1.7 1.7 0 001.8.3h0a1.7 1.7 0 001-1.5V3a2 2 0 114 0v.1a1.7 1.7 0 001 1.5 1.7 1.7 0 001.8-.3l.1-.1a2 2 0 112.8 2.8l-.1.1a1.7 1.7 0 00-.3 1.8v0a1.7 1.7 0 001.5 1H21a2 2 0 110 4h-.1a1.7 1.7 0 00-1.5 1z"/>),
    calendar:     %(<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9h18M8 3v4M16 3v4"/>),
    'map-pin':    %(<path d="M12 22s7-7.5 7-13a7 7 0 10-14 0c0 5.5 7 13 7 13z"/><circle cx="12" cy="9" r="2.5"/>),
    doc:          %(<path d="M6 3h9l4 4v14H6z"/><path d="M14 3v5h5"/>),
    image:        %(<rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><path d="M4 19l5-5 4 4 3-3 4 4"/>),
    materials:    %(<path d="M12 3l9 5-9 5-9-5z"/><path d="M3 13l9 5 9-5"/>),
    stages:       %(<path d="M3 6h18M3 12h18M3 18h12"/>),
    blueprint:    %(<path d="M4 5h16v14H4z"/><path d="M8 5v14M4 10h4M4 15h4M20 10h-4M16 5v14"/>),
    people:       %(<circle cx="9" cy="8" r="3"/><path d="M3 20c0-3.5 2.7-6 6-6s6 2.5 6 6"/><circle cx="17" cy="9" r="2.5"/><path d="M15 20c0-2.5 1.5-4.5 4-4.5"/>),
    money:        %(<rect x="3" y="6" width="18" height="12" rx="2"/><circle cx="12" cy="12" r="2.5"/>),
    note:         %(<path d="M5 4h11l4 4v12H5z"/><path d="M9 12h7M9 16h5"/>),
    sparkles:     %(<path d="M12 3l1.6 4 4 1.6-4 1.6L12 14l-1.6-3.8L6.4 8.6 10.4 7z"/><path d="M19 14l1 2 2 1-2 1-1 2-1-2-2-1 2-1z"/>),
    upload:       %(<path d="M12 4v12M6 10l6-6 6 6M4 20h16"/>),
    download:     %(<path d="M12 4v12M6 14l6 6 6-6M4 20h16"/>),
    more:         %(<circle cx="6" cy="12" r="1.4" fill="currentColor" stroke="none"/><circle cx="12" cy="12" r="1.4" fill="currentColor" stroke="none"/><circle cx="18" cy="12" r="1.4" fill="currentColor" stroke="none"/>),
    x:            %(<path d="M6 6l12 12M6 18L18 6"/>),
    edit:         %(<path d="M14 4l6 6-11 11H3v-6z"/><path d="M13 5l6 6"/>),
    qr:           %(<rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><path d="M14 14h3v3M14 19h3M19 14v3M19 19v2h2"/>),
    shield:       %(<path d="M12 3l8 3v6c0 5-4 8-8 9-4-1-8-4-8-9V6z"/>),
    clock:        %(<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>),
    pin:          %(<path d="M12 3l4 4-2 2 3 3-5 1-1 5-3-3-4 2 2-4-3-3 5-1 2-2z"/>),
  }.freeze
  FALLBACK = %(<circle cx="12" cy="12" r="4"/>).freeze

  def initialize(name:, size: 22, stroke: 1.8, css_class: nil, style: nil)
    @name = name.to_sym
    @size = size
    @stroke = stroke
    @css_class = css_class
    @style = style
  end

  def call
    extras = []
    extras << %(class="#{ERB::Util.html_escape(@css_class)}") if @css_class
    extras << %(style="#{ERB::Util.html_escape(@style)}") if @style
    path = ICONS[@name] || FALLBACK
    %(<svg width="#{@size}" height="#{@size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="#{@stroke}" stroke-linecap="round" stroke-linejoin="round" #{extras.join(' ')}>#{path}</svg>).html_safe
  end
end
