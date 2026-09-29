# frozen_string_literal: true

# 880px right-anchored slide-over showing the contents of a single material
# list: header strip, metadata strip, items table with confidence pills,
# inline-add row, footer with grand total. Mirrors the handoff
# screens/materials.jsx MaterialListDetail.
class Constructors::Projects::Materials::ListDetailComponent < ViewComponent::Base
  STATUS = {
    "draft"             => { label: "Borrador",    tone: :muted },
    "ready_for_review"  => { label: "En revisión", tone: :warn },
    "approved"          => { label: "Aprobada",    tone: :ok }
  }.freeze

  SOURCE = {
    "manual"        => { label: "Carga manual",       icon: :edit },
    "pdf_upload"    => { label: "Importado de PDF",   icon: :doc },
    "excel_upload"  => { label: "Importado de Excel", icon: :grid }
  }.freeze

  def initialize(project:, list:)
    @project = project
    @list = list
  end

  attr_reader :project, :list

  # Editar la lista (aprobar, marcar pagada, agregar/quitar ítems) es editor de
  # obra en adelante — MaterialListPolicy, la misma que usa material_lists#show
  # en su versión de página completa.
  def can_edit?
    return @can_edit if defined?(@can_edit)

    @can_edit = helpers.policy(list).update?
  end

  def status_label;  STATUS.dig(list.status.to_s, :label) || list.status.to_s; end
  def status_tone;   STATUS.dig(list.status.to_s, :tone)  || :muted; end
  def source_label;  SOURCE.dig(list.source_type.to_s, :label) || list.source_type.to_s.titleize; end
  def source_icon;   SOURCE.dig(list.source_type.to_s, :icon)  || :edit; end

  def items
    @items ||= list.material_items.order(created_at: :asc).to_a
  end

  def total_cents
    @total_cents ||= items.sum { |i| (i.quantity.to_f * i.estimated_cost_cents.to_i).round }
  end

  # La lista está pagada si tiene gastos asociados (material_list_id).
  def paid_expenses
    @paid_expenses ||= list.expenses.recent_first.to_a
  end

  def paid?
    paid_expenses.any?
  end

  def paid_cents
    paid_expenses.sum(&:amount_cents)
  end

  def mark_as_paid_path
    helpers.mark_as_paid_constructors_project_material_list_path(project, list)
  end

  def expenses_path
    helpers.constructors_project_expenses_path(project)
  end

  def author_name
    list.author&.email&.split("@")&.first&.titleize || "Sistema"
  end

  def stage_name
    list.project_stage&.name
  end

  def private?
    list.try(:material_list_publication)&.visibility&.to_s == "private"
  end

  def confidence_for(item)
    return :ok if item.try(:confidence).to_s == "alta"
    return :warn if item.try(:confidence).to_s == "media"
    return :bad if item.try(:confidence).to_s == "baja"
    :ok
  end

  def confidence_label(item)
    item.try(:confidence).presence || "alta"
  end
end
