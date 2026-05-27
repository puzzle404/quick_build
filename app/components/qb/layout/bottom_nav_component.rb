# frozen_string_literal: true

# Barra de pestañas inferior para mobile (Constructor OS). Espeja las secciones
# primarias del SidebarComponent vía Qb::Layout::Navigation. La 5ª pestaña
# ("Más") abre el MobileSheetComponent. Sólo visible <768px (ver application.css)
# y oculta dentro de Hotwire Native (el chrome lo provee la app nativa).
class Qb::Layout::BottomNavComponent < ViewComponent::Base
  include Qb::Layout::Navigation

  # Etiquetas cortas para que las 5 pestañas entren en pantallas angostas.
  SHORT_LABELS = {
    dashboard: "Inicio",
    projects: "Proyectos",
    team: "Personas",
    docs: "Biblioteca"
  }.freeze

  def initialize(current:, project: nil, project_sub: nil)
    @current = current&.to_sym || :dashboard
    @project = project
    @project_sub = project_sub&.to_sym
  end

  attr_reader :current, :project, :project_sub

  def label_for(item)
    SHORT_LABELS[item[:key]] || item[:label]
  end

  def tab_style(active)
    color = active ? "var(--color-accent)" : "var(--color-ink-3)"
    weight = active ? 600 : 500
    "flex:1 1 0;min-width:0;display:flex;flex-direction:column;align-items:center;" \
      "justify-content:center;gap:3px;min-height:54px;padding:6px 2px;background:transparent;" \
      "border:none;cursor:pointer;text-decoration:none;color:#{color};font-size:10px;" \
      "font-weight:#{weight};line-height:1;"
  end
end
