# frozen_string_literal: true

# Stroke icon set (16px default, 24x24 viewBox).
# All glyphs come from the Claude Design handoff (icons.jsx). Lookup is by
# symbol; unknown names render a tiny dot so missing icons are visible but
# never crash the page.
class Qb::IconComponent < ViewComponent::Base
  ICONS = {
    home:             %(<path d="M3 11.5L12 4l9 7.5"/><path d="M5 10.5V20h14v-9.5"/><path d="M10 20v-5h4v5"/>),
    dashboard:        %(<rect x="3" y="3" width="7" height="9"/><rect x="14" y="3" width="7" height="5"/><rect x="14" y="12" width="7" height="9"/><rect x="3" y="16" width="7" height="5"/>),
    projects:         %(<path d="M3 7h6l2 2h10v11H3z"/>),
    stages:           %(<path d="M3 6h18M3 12h18M3 18h12"/>),
    planning:         %(<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9h18M8 3v4M16 3v4"/>),
    materials:        %(<path d="M12 3l9 5-9 5-9-5 9-5z"/><path d="M3 13l9 5 9-5"/><path d="M3 18l9 5 9-5"/>),
    blueprint:        %(<path d="M4 5h16v14H4z"/><path d="M8 5v14M4 10h4M4 15h4M20 10h-4M16 5v14"/>),
    people:           %(<circle cx="9" cy="8" r="3"/><path d="M3 20c0-3.5 2.7-6 6-6s6 2.5 6 6"/><circle cx="17" cy="9" r="2.5"/><path d="M15 20c0-2.5 1.5-4.5 4-4.5"/>),
    docs:             %(<path d="M6 3h9l4 4v14H6z"/><path d="M14 3v5h5"/>),
    search:           %(<circle cx="11" cy="11" r="7"/><path d="M20 20l-4-4"/>),
    plus:             %(<path d="M12 5v14M5 12h14"/>),
    bell:             %(<path d="M6 8a6 6 0 1112 0c0 7 3 8 3 8H3s3-1 3-8"/><path d="M10 20a2 2 0 004 0"/>),
    settings:         %(<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 00.3 1.8l.1.1a2 2 0 11-2.8 2.8l-.1-.1a1.7 1.7 0 00-1.8-.3 1.7 1.7 0 00-1 1.5V21a2 2 0 11-4 0v-.1a1.7 1.7 0 00-1-1.5 1.7 1.7 0 00-1.8.3l-.1.1a2 2 0 11-2.8-2.8l.1-.1a1.7 1.7 0 00.3-1.8 1.7 1.7 0 00-1.5-1H3a2 2 0 110-4h.1a1.7 1.7 0 001.5-1 1.7 1.7 0 00-.3-1.8l-.1-.1a2 2 0 112.8-2.8l.1.1a1.7 1.7 0 001.8.3h0a1.7 1.7 0 001-1.5V3a2 2 0 114 0v.1a1.7 1.7 0 001 1.5 1.7 1.7 0 001.8-.3l.1-.1a2 2 0 112.8 2.8l-.1.1a1.7 1.7 0 00-.3 1.8v0a1.7 1.7 0 001.5 1H21a2 2 0 110 4h-.1a1.7 1.7 0 00-1.5 1z"/>),
    'chevron-right':  %(<path d="M9 6l6 6-6 6"/>),
    'chevron-down':   %(<path d="M6 9l6 6 6-6"/>),
    'chevron-up':     %(<path d="M6 15l6-6 6 6"/>),
    'arrow-up':       %(<path d="M12 19V5M6 11l6-6 6 6"/>),
    'arrow-down':     %(<path d="M12 5v14M6 13l6 6 6-6"/>),
    'arrow-right':    %(<path d="M5 12h14M13 5l7 7-7 7"/>),
    filter:           %(<path d="M3 5h18l-7 9v6l-4-2v-4z"/>),
    map:              %(<path d="M9 4l-6 2v14l6-2 6 2 6-2V4l-6 2z"/><path d="M9 4v14M15 6v14"/>),
    money:            %(<rect x="3" y="6" width="18" height="12" rx="1"/><circle cx="12" cy="12" r="3"/>),
    check:            %(<path d="M5 13l4 4 10-10"/>),
    clock:            %(<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>),
    alert:            %(<path d="M12 3l10 17H2z"/><path d="M12 10v4M12 17h0"/>),
    zap:              %(<path d="M13 3L4 14h7l-1 7 9-11h-7z"/>),
    pin:              %(<path d="M12 3l4 4-2 2 3 3-5 1-1 5-3-3-4 2 2-4-3-3 5-1 2-2z"/>),
    dot:              %(<circle cx="12" cy="12" r="3" fill="currentColor" stroke="none"/>),
    upload:           %(<path d="M12 4v12M6 10l6-6 6 6M4 20h16"/>),
    download:         %(<path d="M12 4v12M6 14l6 6 6-6M4 20h16"/>),
    more:             %(<circle cx="6" cy="12" r="1" fill="currentColor"/><circle cx="12" cy="12" r="1" fill="currentColor"/><circle cx="18" cy="12" r="1" fill="currentColor"/>),
    grid:             %(<rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/>),
    list:             %(<path d="M8 6h13M8 12h13M8 18h13"/><circle cx="4" cy="6" r="1" fill="currentColor"/><circle cx="4" cy="12" r="1" fill="currentColor"/><circle cx="4" cy="18" r="1" fill="currentColor"/>),
    kanban:           %(<rect x="3" y="4" width="5" height="14"/><rect x="10" y="4" width="5" height="9"/><rect x="17" y="4" width="5" height="11"/>),
    gantt:            %(<path d="M3 6h8M3 12h14M3 18h10"/><path d="M3 4v16" stroke-width="1"/>),
    sparkles:         %(<path d="M12 3l2 5 5 2-5 2-2 5-2-5-5-2 5-2z"/><path d="M19 14l1 2 2 1-2 1-1 2-1-2-2-1 2-1z"/>),
    ai:               %(<path d="M12 2l2 4 4 2-4 2-2 4-2-4-4-2 4-2z"/><circle cx="19" cy="19" r="2"/><circle cx="5" cy="19" r="1.5"/>),
    layers:           %(<path d="M12 3l9 5-9 5-9-5z"/><path d="M3 13l9 5 9-5"/>),
    close:            %(<path d="M6 6l12 12M6 18L18 6"/>),
    target:           %(<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1.2" fill="currentColor"/>),
    warehouse:        %(<path d="M3 10l9-5 9 5v10H3z"/><path d="M7 20v-6h10v6"/>),
    x:                %(<path d="M6 6l12 12M6 18L18 6"/>),
    calendar:         %(<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9h18M8 3v4M16 3v4"/>),
    image:            %(<rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><path d="M4 19l5-5 4 4 3-3 4 4"/>),
    doc:              %(<path d="M6 3h9l4 4v14H6z"/><path d="M14 3v5h5"/>),
    person:           %(<circle cx="12" cy="8" r="3.5"/><path d="M4 20c0-4 3.5-6 8-6s8 2 8 6"/>),
    trash:            %(<path d="M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13"/><path d="M10 11v6M14 11v6"/>),
    edit:             %(<path d="M14 4l6 6-11 11H3v-6z"/><path d="M13 5l6 6"/>),
  }.freeze

  FALLBACK = %(<circle cx="12" cy="12" r="4"/>).freeze

  def initialize(name:, size: 16, css_class: nil, style: nil)
    @name = name.to_sym
    @size = size
    @css_class = css_class
    @style = style
  end

  def path
    ICONS[@name] || FALLBACK
  end

  def call
    extras = []
    extras << %(class="#{ERB::Util.html_escape(@css_class)}") if @css_class
    extras << %(style="#{ERB::Util.html_escape(@style)}")     if @style
    %(<svg width="#{@size}" height="#{@size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" #{extras.join(' ')}>#{path}</svg>).html_safe
  end
end
