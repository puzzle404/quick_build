# frozen_string_literal: true

# Sticky topbar with breadcrumbs (left) and a small action cluster (right).
class Qb::Layout::TopbarComponent < ViewComponent::Base
  renders_one :right_extra

  def initialize(crumbs: [], user: nil, people_on_site: nil, has_alerts: true)
    @crumbs = Array(crumbs)
    @user = user
    @people_on_site = people_on_site
    @has_alerts = has_alerts
  end

  attr_reader :crumbs, :user, :people_on_site, :has_alerts

  def user_short_name
    return "Usuario" unless user
    name = user.try(:name).presence || user.try(:full_name).presence || user.email.to_s.split("@").first
    name.to_s.titleize
  end

  def user_role
    return nil unless user
    role = user.try(:role).to_s
    return nil if role.blank?
    { "constructor" => "Constructor", "admin" => "Admin", "buyer" => "Cliente", "seller" => "Proveedor" }
      .fetch(role, role.titleize)
  end

  # Proyectos decorados que alimentan el panel de alertas de la campana.
  # Misma fuente que usa el dashboard (AlertStripComponent / DashboardKpis):
  # obras propias MÁS aquellas donde el usuario es miembro. Con
  # `owned_projects` la campana se callaba sobre obras que el usuario sí ve.
  def alert_projects
    @alert_projects ||= begin
      if user.respond_to?(:accessible_projects)
        user.accessible_projects.includes(:project_stages).map { ProjectDecorator.new(_1) }
      else
        []
      end
    rescue StandardError
      []
    end
  end
end
