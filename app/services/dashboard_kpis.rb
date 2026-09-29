# frozen_string_literal: true

# Aggregates the KPIs that the dashboard hero strip + topbar chip + KPI strip
# need. Takes a collection of ProjectDecorator (or anything that responds to
# the same methods) and returns a hash of derived totals — pure read of DB
# state, no side effects.
#
# Used by:
#   - Constructors::DashboardController#index → @kpis
#   - layouts/constructor.html.erb → topbar people_on_site / has_alerts
class DashboardKpis
  def initialize(projects)
    @projects = Array(projects)
  end

  def call
    {
      total_projects:          total_projects,
      in_progress:             count_by_status('in_progress'),
      planned:                 count_by_status('planned'),
      completed:               count_by_status('completed'),
      at_risk:                 at_risk_projects.size,
      budget_total_cents:      sum_int(:budget_cents),
      budget_spent_cents:      sum_int(:spent),
      people_on_site:          people_on_site,
      stages_at_risk:          stages_at_risk,
      has_alerts:              at_risk_projects.any?,
    }
  end

  private

  attr_reader :projects

  def total_projects
    projects.size
  end

  def count_by_status(value)
    projects.count { |p| p.status.to_s == value }
  end

  def at_risk_projects
    @at_risk_projects ||= projects.reject { |p| p.status.to_s == 'completed' }
                                  .select { |p| p.health != :ok }
  end

  def sum_int(method)
    projects.sum { |p| p.public_send(method).to_i }
  end

  # Active project_people across all projects in the scope.
  def people_on_site
    project_ids = projects.map { |p| p.respond_to?(:id) ? p.id : p.try(:object)&.id }.compact
    return 0 if project_ids.empty?
    ProjectPerson.where(project_id: project_ids, status: ProjectPerson.statuses[:active]).count
  end

  # Stages with progress < 100 whose end_date is in the past (overdue).
  def stages_at_risk
    project_ids = projects.map { |p| p.respond_to?(:id) ? p.id : p.try(:object)&.id }.compact
    return 0 if project_ids.empty?
    ProjectStage.where(project_id: project_ids)
                .where('end_date < ?', Date.current)
                .where('COALESCE(progress, 0) < 100')
                .count
  end
end
