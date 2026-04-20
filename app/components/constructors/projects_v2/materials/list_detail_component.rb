# frozen_string_literal: true

# 880px right-anchored slide-over showing the contents of a single material
# list: header strip, metadata strip, items table with confidence pills,
# inline-add row, footer with grand total. Mirrors the handoff
# screens/materials.jsx MaterialListDetail.
class Constructors::ProjectsV2::Materials::ListDetailComponent < ViewComponent::Base
  STATUS = {
    'draft'             => { label: 'Borrador',    tone: :muted },
    'ready_for_review'  => { label: 'En revisión', tone: :warn },
    'approved'          => { label: 'Aprobada',    tone: :ok }
  }.freeze

  SOURCE = {
    'manual'        => { label: 'Carga manual',       icon: :edit },
    'pdf_upload'    => { label: 'Importado de PDF',   icon: :doc },
    'excel_upload'  => { label: 'Importado de Excel', icon: :grid }
  }.freeze

  def initialize(project:, list:)
    @project = project
    @list = list
  end

  attr_reader :project, :list

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

  def author_name
    list.author&.email&.split('@')&.first&.titleize || 'Sistema'
  end

  def stage_name
    list.project_stage&.name
  end

  def private?
    list.try(:material_list_publication)&.visibility&.to_s == 'private'
  end

  def confidence_for(item)
    return :ok if item.try(:confidence).to_s == 'alta'
    return :warn if item.try(:confidence).to_s == 'media'
    return :bad if item.try(:confidence).to_s == 'baja'
    :ok
  end

  def confidence_label(item)
    item.try(:confidence).presence || 'alta'
  end
end
