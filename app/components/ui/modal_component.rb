# frozen_string_literal: true

class Ui::ModalComponent < ViewComponent::Base
  PANEL_WIDTH = {
    sm: "max-w-md",
    md: "max-w-3xl",
    lg: "max-w-4xl",
    xl: "max-w-5xl"
  }.freeze

  def initialize(title:, subtitle: nil, tag_label: nil, size: :xl, body_padding: "px-6 py-6 sm:px-10 sm:py-8", auxiliary_button: nil)
    @title = title
    @subtitle = subtitle
    @tag_label = tag_label
    @panel_width_class = PANEL_WIDTH.fetch(size, PANEL_WIDTH[:xl])
    @body_padding = body_padding
    @auxiliary_button = auxiliary_button&.symbolize_keys
  end

  attr_reader :body_padding, :title, :subtitle, :tag_label, :auxiliary_button

  private

  attr_reader :panel_width_class

  def header?
    title.present? || subtitle.present? || tag_label.present? || auxiliary_button.present?
  end
end
