# frozen_string_literal: true

# Vertical feed of recent activity entries. Accepts the entries hash produced
# by Constructors::DashboardService.recent_activity_entries.
class Constructors::Dashboard::ActivityFeedComponent < ViewComponent::Base
  def initialize(entries: [])
    @entries = Array(entries)
  end

  attr_reader :entries

  def icon_for(entry)
    return :upload   if entry[:icon].to_s.include?('upload')
    return :check    if entry[:icon].to_s.include?('check')
    return :alert    if entry[:icon].to_s.include?('alert')
    return :sparkles if entry[:icon].to_s.include?('ai')
    :clock
  end

  def relative_time(entry)
    return entry[:relative_time] if entry[:relative_time]
    ts = entry[:timestamp]
    return '—' unless ts
    seconds = (Time.current - ts).to_i
    case seconds
    when 0...60          then "Hace un momento"
    when 60...3600       then "Hace #{seconds / 60} min"
    when 3600...86400    then "Hace #{seconds / 3600} h"
    when 86400...2592000 then "Hace #{seconds / 86400} d"
    else "Hace #{seconds / 2592000} meses"
    end
  end
end
