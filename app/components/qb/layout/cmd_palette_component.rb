# frozen_string_literal: true

# Modal command palette opened with ⌘K (or by clicking the trigger in the
# sidebar footer). Items are split into three groups: navigation, actions, and
# the project list. Filtering happens client-side.
class Qb::Layout::CmdPaletteComponent < ViewComponent::Base
  def initialize(projects: [])
    @projects = Array(projects)
  end

  attr_reader :projects

  def items
    nav_items + project_items + action_items
  end

  private

  def nav_items
    [
      { label: 'Ir a Dashboard',     hint: 'Navegación', url: helpers.constructors_dashboard_path },
      { label: 'Ir a Proyectos',     hint: 'Navegación', url: helpers.constructors_projects_path },
    ]
  rescue NoMethodError
    []
  end

  def project_items
    projects.map do |p|
      code = p.try(:code) || "PRJ-#{p.id}"
      { label: p.name.to_s, hint: "Proyecto · #{code}", url: helpers.constructors_project_path(p) }
    end
  rescue NoMethodError
    []
  end

  def action_items
    [
      { label: 'Crear nuevo proyecto', hint: 'Acción', url: safe_url { helpers.new_constructors_project_path } },
    ]
  end

  def safe_url
    yield
  rescue NoMethodError
    '#'
  end
end
