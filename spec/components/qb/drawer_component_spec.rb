# frozen_string_literal: true

require "rails_helper"

RSpec.describe Qb::DrawerComponent, type: :component do
  it "renders eyebrow, title and subtitle in the default header" do
    render_inline(described_class.new(eyebrow: "PRJ-001 · Planificación", title: "Nueva etapa", subtitle: "Etapa raíz")) { "cuerpo" }

    expect(page).to have_css(".qb-drawer-eyebrow", text: "PRJ-001 · Planificación")
    expect(page).to have_css(".qb-drawer-title", text: "Nueva etapa")
    expect(page).to have_css(".qb-drawer-subtitle", text: "Etapa raíz")
    expect(page).to have_css(".qb-drawer-body", text: "cuerpo")
    expect(page).to have_css("button.qb-drawer-close")
  end

  it "supports a custom header slot instead of the default one" do
    render_inline(described_class.new) do |c|
      c.with_custom_header { "<div class=\"my-header\">Custom</div>".html_safe }
      "cuerpo"
    end

    expect(page).to have_css(".my-header", text: "Custom")
    expect(page).to have_no_css(".qb-drawer-eyebrow")
  end

  it "renders an optional sticky footer" do
    render_inline(described_class.new(title: "X")) do |c|
      c.with_footer { "Acciones" }
      "cuerpo"
    end

    expect(page).to have_css(".qb-drawer-footer", text: "Acciones")
  end

  it "omits the footer bar entirely when no footer slot is given" do
    render_inline(described_class.new(title: "X")) { "cuerpo" }

    expect(page).to have_no_css(".qb-drawer-footer")
  end

  it "sets the panel width from the size option" do
    render_inline(described_class.new(title: "X", size: :md)) { "cuerpo" }
    expect(page).to have_css(".qb-drawer-panel[style*='480px']")
  end
end
