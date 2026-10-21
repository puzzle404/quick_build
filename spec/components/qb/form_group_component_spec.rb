# frozen_string_literal: true

require "rails_helper"

# Feedback 21/10: el título de cada sección de un formulario tenía el mismo
# estilo (y era más chico) que las etiquetas de los campos — "Identidad" y
# "Nombre de la etapa" se leían iguales. La sección usa su propia clase
# (.qb-form-section-title: sans, 13px, semibold, tinta) y la etiqueta sigue
# siendo .qb-label (mono, versalitas, gris).
RSpec.describe Qb::FormGroupComponent, type: :component do
  it "el título de la sección se distingue de las etiquetas de los campos" do
    render_inline(described_class.new(title: "Identidad")) { '<label class="qb-label">Nombre</label>'.html_safe }

    expect(page).to have_css(".qb-form-section .qb-form-section-title", text: "Identidad")
    expect(page).to have_no_css(".qb-label", text: "Identidad")
  end

  it "plegable: el título también es de sección" do
    render_inline(described_class.new(title: "Dependencias", collapsible: true, open: false)) { "x" }

    expect(page).to have_css("details.qb-form-section summary .qb-form-section-title", text: "Dependencias", visible: :all)
  end
end
