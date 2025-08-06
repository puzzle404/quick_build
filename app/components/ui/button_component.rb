# frozen_string_literal: true

class Ui::ButtonComponent < ViewComponent::Base
  VARIANT_CLASSES = {
    primary: "bg-indigo-600 text-white hover:bg-indigo-700",
    secondary: "bg-gray-600 text-white hover:bg-gray-700",
    danger: "bg-red-600 text-white hover:bg-red-700"
  }.freeze

  def initialize(label:, path:, method: :get, data: {}, variant: :primary)
    @label = label
    @path = path
    @method = method
    @data = data
    @variant = variant
  end

  def call
    classes = "inline-flex items-center rounded px-4 py-2 font-semibold #{VARIANT_CLASSES[@variant]}"
    options = { class: classes, data: @data }
    if @method.to_sym == :get
      link_to @label, @path, options
    else
      button_to @label, @path, options.merge(method: @method)
    end
  end
end
