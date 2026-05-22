# frozen_string_literal: true

# Computes attendance KPIs for a project's team over a rolling window:
# average attendance %, hours logged, planned hours (from working days),
# and labor cost in cents (hours × hourly_rate_cents per person).
class TeamAttendanceStats
  DEFAULT_HOURS_PER_DAY = 8 # used as planned-hours when person.hourly_rate is set

  def initialize(project, window_days: 30)
    @project = project
    @window_days = window_days
  end

  def call
    {
      avg_attendance_pct: average_attendance_pct,
      hours_logged:       hours_logged,
      planned_hours:      planned_hours,
      labor_cost_cents:   labor_cost_cents,
      window_days:        @window_days
    }
  end

  private

  attr_reader :project, :window_days

  # Percentage of days each active person actually showed up across the
  # window, averaged across people.
  def average_attendance_pct
    people = project.project_people.where(status: ProjectPerson.statuses[:active])
    return nil if people.empty?

    window_start = window_days.days.ago.beginning_of_day
    window_end   = Time.current.end_of_day
    business_days = working_days(window_start.to_date, window_end.to_date)
    return nil if business_days.zero?

    person_pcts = people.map do |person|
      distinct_days = person.person_attendances
                            .where(occurred_at: window_start..window_end)
                            .pluck(:occurred_at)
                            .map(&:to_date)
                            .uniq.size
      (distinct_days.to_f / business_days * 100).round
    end
    return nil if person_pcts.empty?

    (person_pcts.sum.to_f / person_pcts.size).round
  end

  def working_days(from, to)
    (from..to).count { |d| ![0, 6].include?(d.wday) } # Mon–Fri
  end

  # Sum of `hours` across all attendance records in the window. nil when
  # there are no records (so the UI can still show a dash instead of "0 h").
  def hours_logged
    sum = attendances_in_window.sum(:hours)
    sum&.positive? ? sum.to_f.round(1) : nil
  end

  # Active people × default 8h × working days. Intended as an aspiration —
  # nil when there are no people.
  def planned_hours
    active_count = project.project_people.where(status: ProjectPerson.statuses[:active]).count
    return nil if active_count.zero?
    bd = working_days(window_days.days.ago.to_date, Date.current)
    return nil if bd.zero?
    active_count * DEFAULT_HOURS_PER_DAY * bd
  end

  # Sum over each attendance: hours × person.hourly_rate_cents. nil when
  # there isn't a single person with both rate and hours.
  def labor_cost_cents
    rows = attendances_in_window
             .joins(:project_person)
             .where.not(project_people: { hourly_rate_cents: nil })
             .where.not(hours: nil)
             .pluck(:hours, 'project_people.hourly_rate_cents')
    return nil if rows.empty?
    rows.sum { |h, rate| (h.to_f * rate.to_i).round }
  end

  def attendances_in_window
    @attendances_in_window ||= PersonAttendance.joins(:project_person)
                                               .where(project_people: { project_id: project.id })
                                               .where(occurred_at: window_days.days.ago.beginning_of_day..Time.current.end_of_day)
  end
end
