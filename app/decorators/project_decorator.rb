# frozen_string_literal: true

class ProjectDecorator < BaseDecorator
  delegate_all

  def total_members
    members.count
  end

  def attachments_count
    object.images.count
  end

  def elapsed_days
    return unless start_date

    [(Date.current - start_date).to_i, 0].max
  end

  def duration_text
    return unless start_date && end_date

    days = (end_date - start_date).to_i + 1
    "#{days} días"
  end

  def duration_hint
    duration_text ? 'Calculado a partir de las fechas de inicio y fin cargadas.' : 'Registra fechas de inicio y fin para calcular la duración estimada.'
  end

  def time_elapsed_hint
    elapsed_days ? 'días desde el inicio' : 'A definir'
  end

  def location_label
    location.presence || 'Ubicación no indicada'
  end

  def coordinates_status
    located? ? 'Coordenadas cargadas' : 'Coordenadas pendientes'
  end

  def coordinates_badge_color
    located? ? 'bg-emerald-500' : 'bg-slate-300'
  end

  def coordinates_label
    return unless located?

    "Lat: #{helpers.number_with_precision(latitude, precision: 4)} · Lng: #{helpers.number_with_precision(longitude, precision: 4)}"
  end

  def member_options
    User.order(:email).map { |user| [user.email, user.id] }
  end
end
