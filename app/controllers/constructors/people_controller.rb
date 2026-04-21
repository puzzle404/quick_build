# frozen_string_literal: true

# Global Personas screen — cross-project view of every team member the
# constructor has across their owned projects. Mirrors team.jsx from the
# Claude Design handoff. Per-project people management still lives under
# Constructors::Projects::PeopleController.
class Constructors::PeopleController < Constructors::BaseController
  def index
    authorize :people, :index_global?
    @current_qb_section = :team

    @query = params[:q].to_s.strip.downcase

    # Project-people across all owned projects, decorated for the table.
    base = ProjectPerson.joins(:project)
                        .where(projects: { owner_id: current_user.id })
                        .includes(:project)

    base = base.where('LOWER(full_name) LIKE ?', "%#{@query}%") if @query.present?

    rows = base.to_a

    # Group by (full_name, phone) so the same person on N projects becomes
    # one row with N "Asignada a" pills.
    @grouped = rows.group_by { |p| [p.full_name, p.phone] }.map do |key, ppl|
      first = ppl.first
      {
        full_name:        first.full_name,
        phone:            first.phone,
        role_title:       first.role_title,
        document_id:      first.document_id,
        status:           ppl.any? { |p| p.status.to_s == 'active' } ? 'active' : 'inactive',
        hourly_rate_cents: ppl.map { |p| p.try(:hourly_rate_cents) }.compact.max,
        projects:         ppl.map(&:project).uniq,
        attendance_days:  attendance_days_for(ppl),
        attendance_pct:   attendance_pct_for(ppl)
      }
    end

    @pagy, @grouped_page = pagy_array(@grouped, limit: 25)

    @kpis = compute_kpis(rows)
  end

  private

  # No Pundit policy class for ":people" symbol — we authorize via base. If
  # the user is a constructor (BaseController#ensure_constructor!), let
  # them in. Anything else 403.
  def authorize(*); current_user&.constructor? || raise(Pundit::NotAuthorizedError); end

  def attendance_days_for(people)
    PersonAttendance.where(project_person_id: people.map(&:id))
                    .where(occurred_at: Date.current.beginning_of_month..Time.current.end_of_day)
                    .pluck(:occurred_at)
                    .map(&:to_date)
                    .uniq.size
  end

  def attendance_pct_for(people)
    window_days = 30
    business_days = (window_days.days.ago.to_date..Date.current).count { |d| ![0, 6].include?(d.wday) }
    return nil if business_days.zero?
    distinct = PersonAttendance.where(project_person_id: people.map(&:id))
                               .where(occurred_at: window_days.days.ago.beginning_of_day..Time.current.end_of_day)
                               .pluck(:occurred_at)
                               .map(&:to_date)
                               .uniq.size
    (distinct.to_f / business_days * 100).round
  end

  def compute_kpis(rows)
    active = rows.count { |p| p.status.to_s == 'active' }
    on_leave = rows.count { |p| p.status.to_s == 'inactive' }

    pcts = rows.group_by(&:id).keys.map { |id| attendance_pct_for([ProjectPerson.find(id)]) }.compact
    avg_attendance = pcts.empty? ? nil : (pcts.sum.to_f / pcts.size).round

    cost_cents = PersonAttendance.joins(:project_person)
                                 .where(project_people: { id: rows.map(&:id) })
                                 .where.not(hours: nil)
                                 .where.not(project_people: { hourly_rate_cents: nil })
                                 .where(occurred_at: Date.current.beginning_of_month..Time.current.end_of_day)
                                 .pluck(:hours, 'project_people.hourly_rate_cents')
                                 .sum { |h, rate| (h.to_f * rate.to_i).round }

    {
      total: rows.size,
      active: active,
      on_leave: on_leave,
      avg_attendance_pct: avg_attendance,
      labor_cost_cents: cost_cents.zero? ? nil : cost_cents
    }
  end
end
