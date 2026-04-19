# frozen_string_literal: true

# Vertical list of upcoming project stages (next 14 days), with avatar of the
# lead (or the project), short due copy and budget badge.
class Constructors::DashboardV2::UpcomingStagesComponent < ViewComponent::Base
  def initialize(stages: [])
    @stages = Array(stages)
  end

  attr_reader :stages

  def project_code(stage)
    p = stage.respond_to?(:project) ? stage.project : nil
    return '—' unless p
    ProjectDecorator.new(p).code
  end

  def short_when(stage)
    return '—' unless stage.start_date
    days = (stage.start_date - Date.current).to_i
    return 'Empieza hoy' if days <= 0
    "Empieza en #{days}d"
  end

  def lead_name(stage)
    stage.try(:lead).presence || 'Sin asignar'
  end

  def stage_budget(stage)
    stage.try(:budget_cents).to_i
  end
end
