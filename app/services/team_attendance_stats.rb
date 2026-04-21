# frozen_string_literal: true

# Computes attendance KPIs for a project's team over a rolling window.
# Hours/cost KPIs are not implementable yet — PersonAttendance has no hours
# field and ProjectPerson has no hourly_rate; both stay nil until those
# columns exist (see TODO in #call).
class TeamAttendanceStats
  def initialize(project, window_days: 30)
    @project = project
    @window_days = window_days
  end

  def call
    {
      avg_attendance_pct: average_attendance_pct,
      hours_logged:       nil, # TODO: needs PersonAttendance#hours column
      planned_hours:      nil, # TODO: needs ProjectPerson#planned_hours/week
      labor_cost_cents:   nil, # TODO: needs ProjectPerson#hourly_rate_cents
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
end
