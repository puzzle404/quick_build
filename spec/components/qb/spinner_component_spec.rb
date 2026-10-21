# frozen_string_literal: true

require "rails_helper"

RSpec.describe Qb::SpinnerComponent, type: :component do
  it "bloques: cuatro ladrillos, accesible como status" do
    render_inline(described_class.new(variant: :blocks, size: 32))

    expect(page).to have_css(".qb-spinner-blocks[role=status][aria-label='Cargando'] > span", count: 4)
    expect(page.find(".qb-spinner-blocks")[:style]).to include("--qb-spinner-size:32px")
  end

  it "anillo con etiqueta: el texto es el nombre accesible" do
    render_inline(described_class.new(variant: :ring, size: 12, label: "Buscando…", stacked: false))

    expect(page).to have_css("[role=status] .qb-spinner-ring[aria-hidden=true]")
    expect(page).to have_css("[role=status] .qb-spinner-label", text: "Buscando…")
  end

  it "una variante desconocida cae en bloques" do
    render_inline(described_class.new(variant: :nope))

    expect(page).to have_css(".qb-spinner-blocks")
  end
end

RSpec.describe Qb::DrawerSkeletonComponent, type: :component do
  it "arma un panel de drawer con bloques y esqueleto, cerrable" do
    render_inline(described_class.new)

    expect(page).to have_css(".qb-drawer-panel .qb-spinner-blocks")
    expect(page).to have_css(".qb-drawer-panel .qb-skeleton", minimum: 5)
    expect(page).to have_css("button[aria-label=Cerrar]")
  end
end
