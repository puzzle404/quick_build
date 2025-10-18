# frozen_string_literal: true

class Ui::ButtonComponent < ViewComponent::Base
  BASE_CLASSES = "inline-flex items-center justify-center gap-2 font-semibold rounded-full transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"
  SIZE_CLASSES = {
    sm: "px-3 py-1 text-xs",
    md: "px-5 py-2 text-sm",
    lg: "px-6 py-3 text-base"
  }.freeze

  VARIANT_CLASSES = {
    primary:   "bg-indigo-600 text-white shadow-sm hover:bg-indigo-700 focus-visible:outline-indigo-500",
    secondary: "border border-slate-200 bg-white text-slate-700 hover:border-slate-300 hover:text-slate-900 focus-visible:outline-indigo-500",
    danger:    "border border-rose-200 bg-white text-rose-600 hover:border-rose-400 hover:text-rose-700 focus-visible:outline-rose-500",
    link:      "bg-transparent text-indigo-600 shadow-none hover:text-indigo-700 focus-visible:outline-indigo-500"
  }.freeze

  # Params:
  # - label: texto del botón/enlace
  # - path: url/path o helper de ruta. Si no se pasa, se renderiza un <button>.
  # - turbo_method / method: :get, :post, :patch, :put, :delete (default :get)
  # - data: hash extra para data-*
  # - variant: :primary | :secondary | :danger
  # - size: :sm | :md | :lg
  # - turbo_confirm: String (muestra confirm antes de enviar)
  # - turbo_frame: String (id del frame)
  # - turbo: true/false (permite desactivar Turbo para esta acción)
  # - disabled: true/false
  # - type: :button | :submit | :reset (para <button>)
  # - class_name: string adicional que se suma a las clases generadas
  # - html_options: opciones extra que se fusionan con el tag final
  def initialize(label:, path: nil, turbo_method: :get, method: nil, data: {}, variant: :primary,
                 size: :md, turbo_confirm: nil, turbo_frame: nil, turbo: true, disabled: false,
                 type: nil, class_name: nil, html_options: {})
    @label          = label
    @path           = path
    @method         = (method || turbo_method || :get)&.to_sym
    @user_data      = (data || {}).deep_dup
    @variant        = variant
    @size           = size
    @turbo_confirm  = turbo_confirm
    @turbo_frame    = turbo_frame
    @turbo_enabled  = turbo
    @disabled       = disabled
    @type           = type
    @extra_classes  = class_name
    @html_options   = (html_options || {}).deep_dup
  end

  def call
    @classes = composed_classes
    if path_present?
      build_link_or_button
    else
      build_plain_button
    end
  end

  class << self
    def classes_for(variant: :primary, size: :md, extra: nil)
      [
        BASE_CLASSES,
        SIZE_CLASSES.fetch(size, SIZE_CLASSES[:md]),
        VARIANT_CLASSES.fetch(variant, VARIANT_CLASSES[:primary]),
        extra
      ].compact.join(" ")
    end
  end

  private

  def composed_classes
    self.class.classes_for(
      variant: @variant,
      size: @size,
      extra: @html_options.delete(:class) || @extra_classes
    )
  end

  # Construye los data-* comunes para enlaces/botones
  def build_data_attrs
    data = @user_data.deep_dup

    data[:turbo_confirm] = @turbo_confirm if @turbo_confirm.present?
    data[:turbo] = false unless @turbo_enabled
    data[:turbo_frame] = @turbo_frame if @turbo_frame.present? && @method == :get

    data
  end

  # Para button_to, el frame va en form: { data: { turbo_frame: ... } }
  def build_form_attrs
    return {} unless @turbo_frame.present? && @method != :get

    { form: { data: { turbo_frame: @turbo_frame } } }
  end

  def path_present?
    @path.present?
  end

  def build_plain_button
    options = @html_options.deep_dup
    options[:class] = @classes
    options[:data] = merge_data(options[:data], @user_data)
    options[:type] = @type || :button
    options[:disabled] = true if @disabled

    button_tag @label, options
  end

  def build_link_or_button
    if @method == :get
      link_to @label, @path, link_options
    else
      # Para métodos no-GET siempre usamos <form> con button_to (fiable con y sin Turbo)
      button_to @label, @path, button_to_options
    end
  end

  def link_options
    options = @html_options.deep_dup
    options[:class] = @classes
    options[:data] = merge_data(options[:data], build_data_attrs)
    options[:disabled] = true if @disabled

    if @disabled
      options[:aria] = merge_hash(options[:aria], { disabled: true })
      options[:class] = "#{options[:class]} pointer-events-none opacity-70"
    end

    options
  end

  def button_to_options
    options = link_options
    options[:method] = @method
    options[:form] = merge_hash(options[:form], build_form_attrs[:form])
    options
  end

  def merge_data(existing, new_data)
    existing_data = (existing || {}).deep_dup
    existing_data.merge(new_data || {})
  end

  def merge_hash(existing, new_hash)
    return new_hash if existing.blank?
    return existing if new_hash.blank?

    existing.deep_merge(new_hash)
  end
end
