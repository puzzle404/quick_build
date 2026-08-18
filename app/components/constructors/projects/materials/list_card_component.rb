# frozen_string_literal: true

# Card representation of a material list in the grid view.
class Constructors::Projects::Materials::ListCardComponent < ViewComponent::Base
  STATUS_LABELS = {
    'draft'             => 'Borrador',
    'ready_for_review'  => 'En revisión',
    'approved'          => 'Aprobada',
  }.freeze

  STATUS_TONES = {
    'draft'             => :muted,
    'ready_for_review'  => :warn,
    'approved'          => :ok,
  }.freeze

  SOURCE_LABELS = {
    'manual'        => 'Manual',
    'pdf_upload'    => 'PDF',
    'excel_upload'  => 'Excel',
  }.freeze

  SOURCE_ICONS = {
    'manual'        => :edit,
    'pdf_upload'    => :doc,
    'excel_upload'  => :grid,
  }.freeze

  def initialize(project:, list:)
    @project = project
    @list = list
  end

  attr_reader :project, :list

  def status_label; STATUS_LABELS[list.status.to_s] || list.status.to_s; end
  def status_tone; STATUS_TONES[list.status.to_s] || :muted; end
  def source_label; SOURCE_LABELS[list.source_type.to_s] || list.source_type.to_s.titleize; end
  def source_icon; SOURCE_ICONS[list.source_type.to_s] || :edit; end

  def items_count
    @items_count ||= list.material_items.count
  end

  def total_cents
    @total_cents ||= list.material_items.to_a.sum { |i| (i.quantity.to_f * i.estimated_cost_cents.to_i).round }
  end

  def author_name
    list.author&.email&.split('@')&.first&.titleize || 'Sistema'
  end

  def stage_name
    list.project_stage&.name
  end

  def is_pdf?
    list.source_type.to_s == 'pdf_upload'
  end

  def private?
    list.try(:material_list_publication)&.visibility&.to_s == 'private'
  end
end
