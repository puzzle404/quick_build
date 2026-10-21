# frozen_string_literal: true

# Bottom sheet "Más" que abre la 5ª pestaña del BottomNavComponent. Reúne lo que
# en escritorio vive en el sidebar/topbar: switcher de empresa, búsqueda, alta de
# proyecto, sub-nav del proyecto activo, apariencia y cierre de sesión.
class Qb::Layout::MobileSheetComponent < ViewComponent::Base
  include Qb::Layout::Navigation

  def initialize(project: nil, project_sub: nil, user: nil, company_name: nil)
    @project = project
    @project_sub = project_sub&.to_sym
    @user = user
    @company_name = company_name
  end

  attr_reader :project, :project_sub, :user, :company_name

  def display_company
    company_name.presence || "Quick Build"
  end

  def row_style(active = false)
    bg = active ? "var(--color-bg-sunken)" : "transparent"
    color = active ? "var(--color-ink)" : "var(--color-ink-2)"
    "display:flex;align-items:center;gap:12px;width:100%;min-height:48px;padding:0 14px;" \
      "background:#{bg};color:#{color};border:none;border-radius:8px;font-size:14px;" \
      "font-weight:500;text-decoration:none;cursor:pointer;text-align:left;"
  end

  def section_label_style
    "padding:12px 14px 4px;font-size:10px;font-family:var(--font-mono);color:var(--color-ink-4);" \
      "letter-spacing:1px;text-transform:uppercase;font-weight:500;"
  end
end
