module ApplicationHelper
  def user_signed_in?
    authenticated?
  end

  # Contextual greeting based on time of day
  def greeting_for_time_of_day
    hour = Time.current.hour
    case hour
    when 5..11 then "Buenos días"
    when 12..17 then "Buenas tardes"
    else "Buenas noches"
    end
  end
end
