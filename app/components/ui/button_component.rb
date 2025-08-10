# frozen_string_literal: true

class Ui::ButtonComponent < ViewComponent::Base
  VARIANT_CLASSES = {
    primary:   "bg-indigo-600 text-white hover:bg-indigo-700",
    secondary: "bg-gray-600 text-white hover:bg-gray-700",
    danger:    "bg-red-600 text-white hover:bg-red-700"
  }.freeze

  # Params:
  # - label: texto del botón/enlace
  # - path: url/path o helper de ruta
  # - turbo_method: :get, :post, :patch, :put, :delete (default :get)
  # - data: hash extra para data-*
  # - variant: :primary | :secondary | :danger
  # - turbo_confirm: String (muestra confirm antes de enviar)
  # - turbo_frame: String (id del frame)
  # - turbo: true/false (permite desactivar Turbo para esta acción)
  def initialize(label:, path:, turbo_method: :get, data: {}, variant: :primary,
                 turbo_confirm: nil, turbo_frame: nil, turbo: true)
                 
    @label          = label
    @path           = path
    @method         = turbo_method.to_sym
    @user_data      = data || {}
    @variant        = variant
    @turbo_confirm  = turbo_confirm
    @turbo_frame    = turbo_frame
    @turbo_enabled  = turbo
  end

  def call
    set_classes
    build_link_or_button
  end

  private

  def set_classes
    @classes = "inline-flex items-center rounded px-4 py-2 font-semibold #{VARIANT_CLASSES[@variant]}"
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

  def build_link_or_button
    if @method == :get
      link_to @label, @path, class: @classes, data: build_data_attrs
    else
      # Para métodos no-GET siempre usamos <form> con button_to (fiable con y sin Turbo)
      options = { class: @classes, data: build_data_attrs, method: @method }.merge(build_form_attrs)
      button_to @label, @path, options
    end
  end
end
