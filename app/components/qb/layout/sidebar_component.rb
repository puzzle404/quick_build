# frozen_string_literal: true

# Persistent left rail with brand, primary nav, project context (when inside a
# project), pinned projects (when not), search trigger, and a collapse toggle.
# Mirrors the structure of the Claude Design handoff (chrome.jsx).
class Qb::Layout::SidebarComponent < ViewComponent::Base
  NAV = [
    { key: :dashboard, label: 'Dashboard',   icon: :dashboard },
    { key: :projects,  label: 'Proyectos',   icon: :projects, badge_kind: :project_count },
    { key: :team,      label: 'Personas',    icon: :people },
    { key: :docs,      label: 'Biblioteca',  icon: :docs },
  ].freeze

  PROJECT_NAV = [
    { key: :overview,   label: 'Resumen',       icon: :home },
    { key: :planning,   label: 'Planificación', icon: :planning },
    { key: :materials,  label: 'Materiales',    icon: :materials },
    { key: :blueprints, label: 'Planos · IA',   icon: :blueprint, accent: true },
    { key: :team,       label: 'Equipo',        icon: :people },
    { key: :docs,       label: 'Documentos',    icon: :docs },
  ].freeze

  def initialize(current:, user:, project: nil, project_sub: nil,
                 project_count: nil, pinned_projects: [], company_name: nil)
    @current = current&.to_sym || :dashboard
    @user = user
    @project = project
    @project_sub = project_sub&.to_sym
    @project_count = project_count
    @pinned_projects = Array(pinned_projects)
    @company_name = company_name
  end

  attr_reader :current, :user, :project, :project_sub, :pinned_projects, :company_name

  def nav_items
    NAV.map { |n| n.merge(active: n[:key] == current, url: nav_url(n[:key])) }
  end

  def project_nav_items
    return [] unless project
    PROJECT_NAV.map { |n| n.merge(active: n[:key] == project_sub, url: project_url(n[:key])) }
  end

  def project_url(sub_key)
    case sub_key
    when :overview   then helpers.constructors_project_path(project)
    when :planning   then helpers.constructors_project_planning_path(project)
    when :materials  then helpers.constructors_project_material_lists_path(project)
    when :blueprints then helpers.constructors_project_blueprints_path(project)
    when :team       then helpers.constructors_project_people_path(project)
    when :docs       then helpers.constructors_project_documents_path(project)
    end
  rescue NoMethodError
    '#'
  end

  def nav_url(key)
    case key
    when :dashboard then helpers.constructors_dashboard_path
    when :projects  then helpers.constructors_projects_path
    when :team      then helpers.constructors_projects_path
    when :docs      then helpers.constructors_projects_path
    else '#'
    end
  rescue NoMethodError
    '#'
  end

  def new_project_url
    helpers.new_constructors_project_path
  rescue NoMethodError
    '#'
  end

  def project_short_name
    return nil unless project
    project.name.to_s.split('·').first.to_s.strip.presence || project.name.to_s
  end

  def project_progress
    project&.progress.to_i
  end

  def project_planned_progress
    project&.planned_progress.to_i
  end

  def project_health
    project&.health || :ok
  end

  def project_code
    project&.code
  end

  def project_stages_done
    project&.stages_done.to_i
  end

  def project_stages_count
    project&.stages_count.to_i
  end

  def display_company
    company_name.presence || 'Quick Build'
  end

  # Style helpers — keep markup readable in the template.

  def nav_link_style(item)
    active = item[:active]
    bg = active ? 'var(--color-bg-sunken)' : 'transparent'
    color = active ? 'var(--color-ink)' : 'var(--color-ink-2)'
    weight = active ? 600 : 500
    "width:100%;display:flex;align-items:center;gap:10px;padding:0 10px;height:30px;margin-bottom:1px;background:#{bg};color:#{color};border:none;border-radius:5px;cursor:pointer;font-size:12.5px;font-weight:#{weight};text-decoration:none;position:relative;"
  end

  def project_nav_link_style(item)
    active = item[:active]
    bg = active ? 'var(--color-bg-sunken)' : 'transparent'
    color = active ? 'var(--color-ink)' : 'var(--color-ink-2)'
    weight = active ? 600 : 500
    "width:100%;display:flex;align-items:center;gap:10px;padding:0 10px;height:28px;margin-bottom:1px;background:#{bg};color:#{color};border:none;border-radius:5px;cursor:pointer;font-size:12px;font-weight:#{weight};text-decoration:none;position:relative;"
  end

  def project_chip_style
    'padding:8px 10px;border-radius:6px;background:color-mix(in oklab, var(--color-accent) 8%, var(--color-bg-sunken));border:1px solid color-mix(in oklab, var(--color-accent) 18%, var(--color-line));'
  end
end
