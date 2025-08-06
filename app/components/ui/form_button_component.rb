# frozen_string_literal: true

class Ui::FormButtonComponent < ViewComponent::Base
  def initialize(form:, label: nil, variant: :primary)
    @form = form
    @label = label
    @variant = variant
  end

  def call
    classes = Ui::ButtonComponent::VARIANT_CLASSES[@variant]
    @form.submit(@label, class: "inline-flex items-center rounded px-4 py-2 font-semibold #{classes}")
  end
end
