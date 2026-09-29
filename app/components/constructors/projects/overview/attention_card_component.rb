# frozen_string_literal: true

# Tarjeta "Requiere atención" del panel del proyecto: lo que pide una acción,
# de lo más grave a lo menos, con a lo sumo MAX_SHOWN visibles.
#
#   · Entrega vencida            → Reprogramar (edición en el drawer)
#   · Gasto sobre presupuesto    → Ver gastos
#   · Etapas atrasadas           → Ver (baja a la tarjeta de la más atrasada)
#   · Etapa que vence en ≤14 días → Abrir (detalle en el drawer)
#
# "Avance por debajo del plan" no va acá: ya lo cuenta la tarjeta de Avance.
# Se arma con las raíces ya cargadas por projects#show (sin queries extra).
class Constructors::Projects::Overview::AttentionCardComponent < ViewComponent::Base
  MAX_SHOWN = 3
  SOON_DAYS = 14
  # Sin `helpers`: #items se puede pedir antes del render (ej: para contar),
  # y ahí ViewComponent no tiene view context. (`format` tampoco: en un
  # ViewComponent es otro método — ver CLAUDE.md, rough edges.)
  ROUTES = Rails.application.routes.url_helpers
  FMT = ApplicationController.helpers

  Item = Struct.new(:tone, :glyph, :title, :body, :cta, :href, :data, keyword_init: true)

  def initialize(project:, stages:, today: Date.current)
    @project = project.is_a?(ProjectDecorator) ? project : ProjectDecorator.new(project)
    @stages = stages
    @today = today
  end

  attr_reader :project

  def items
    @items ||= [ overdue_delivery, overcost, overdue_stages, *due_soon ].compact
  end

  def shown_items
    items.first(MAX_SHOWN)
  end

  def hidden_count
    [ items.size - MAX_SHOWN, 0 ].max
  end

  private

  def drawer_data
    { turbo_frame: "drawer", action: "click->qb--drawer#open" }
  end

  def fmt(date)
    FMT.qb_fmt_date_short(date)
  end

  def overdue_delivery
    due = @project.end_date
    return if due.blank? || due >= @today || @project.completed?

    days = (@today - due).to_i
    Item.new(tone: :bad, glyph: "!", title: "Entrega vencida",
             body: "Era el #{fmt(due)} · hace #{days} #{days == 1 ? 'día' : 'días'}",
             cta: "Reprogramar", href: ROUTES.edit_constructors_project_path(@project), data: drawer_data)
  end

  def overcost
    budget = @project.budget_cents.to_i
    spent = @project.spent_to_date_cents.to_i
    return if budget <= 0 || spent <= budget

    over = ((spent.to_f / budget - 1) * 100).round
    Item.new(tone: :bad, glyph: "$", title: "Gasto sobre presupuesto",
             body: "+#{over}% · #{FMT.qb_fmt_cents(spent)} de #{FMT.qb_fmt_cents(budget)}",
             cta: "Ver gastos", href: ROUTES.constructors_project_expenses_path(@project), data: {})
  end

  def overdue_stages
    late = pending.select { |s| s.end_date < @today }
    return if late.empty?

    names = late.first(2).map(&:name)
    body = late.size > 2 ? "#{names.join(', ')} y #{late.size - 2} más" : names.join(" y ")
    Item.new(tone: :warn, glyph: late.size.to_s, title: late.size == 1 ? "Etapa atrasada" : "Etapas atrasadas",
             body: body, cta: "Ver", href: "##{ActionView::RecordIdentifier.dom_id(late.first, :card)}", data: {})
  end

  def due_soon
    pending.select { |s| s.end_date >= @today && s.end_date <= @today + SOON_DAYS }.map do |s|
      days = (s.end_date - @today).to_i
      when_label = days.zero? ? "vence hoy" : "vence en #{days} #{days == 1 ? 'día' : 'días'}"
      lead = s.try(:lead).presence
      Item.new(tone: :neutral, glyph: "#{days}d", title: "#{s.name} #{when_label}",
               body: [ "Avance #{s.progress.to_i}%", lead ].compact.join(" · "),
               cta: "Abrir", href: ROUTES.constructors_project_stage_path(@project, s), data: drawer_data)
    end
  end

  # Etapas principales sin terminar y con fecha de fin, por fecha.
  def pending
    @pending ||= @stages.select { |s| s.end_date.present? && s.progress.to_i < 100 }
                        .sort_by { |s| [ s.end_date, s.position.to_i ] }
  end
end
