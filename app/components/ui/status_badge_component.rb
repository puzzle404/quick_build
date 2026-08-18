# frozen_string_literal: true

module Ui
  class StatusBadgeComponent < ViewComponent::Base
    TONES = %i[primary secondary accent neutral info success warning error].freeze

    def initialize(text:, tone: :neutral, outline: false, class_name: nil)
      @text = text
      @tone = (tone || :neutral).to_sym
      @outline = outline
      @extra = class_name
    end

    def call
      content_tag :div, @text, class: classes
    end

    private

    def classes
      # Opaque light background with darker border and readable dark text
      bg, text, border = color_classes(@tone)
      [
        "badge inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold",
        bg,
        text,
        "border",
        border,
        (@outline ? "badge-outline" : nil),
        @extra
      ].compact.join(" ")
    end

    def color_classes(tone)
      case tone
      when :primary
        ["bg-indigo-100", "text-indigo-700", "border-indigo-200"]
      when :secondary
        ["bg-slate-100", "text-slate-700", "border-slate-200"]
      when :accent
        ["bg-rose-100", "text-rose-700", "border-rose-200"]
      when :neutral
        ["bg-slate-100", "text-slate-700", "border-slate-200"]
      when :info
        ["bg-sky-100", "text-sky-700", "border-sky-200"]
      when :success
        ["bg-emerald-100", "text-emerald-700", "border-emerald-200"]
      when :warning
        ["bg-yellow-100", "text-yellow-700", "border-yellow-200"]
      when :error
        ["bg-rose-100", "text-rose-700", "border-rose-200"]
      else
        ["bg-slate-100", "text-slate-700", "border-slate-200"]
      end
    end
  end
end
