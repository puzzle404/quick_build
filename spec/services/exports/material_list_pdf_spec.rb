# frozen_string_literal: true

require "rails_helper"

RSpec.describe Exports::MaterialListPdf do
  let(:project) { create(:project, name: "Torre Aurora") }
  let(:stage) { create(:project_stage, project: project, name: "Replanteo") }
  let(:list) { create(:material_list, project: project, project_stage: stage, name: "Hierros", add_default_item: false) }

  before do
    create(:material_item, material_list: list, name: "Hierro 8 mm", quantity: 12.5, unit: "barra",
                           estimated_cost_cents: 987_654, notes: "Entregar en obra")
  end

  def pdf_text(pdf)
    PDF::Reader.new(StringIO.new(pdf.render)).pages.map(&:text).join("\n")
  end

  it "es un PDF con obra, etapa, código e ítems — y SIN precios" do
    pdf = described_class.new(list)
    text = pdf_text(pdf)

    expect(pdf.render).to start_with("%PDF")
    expect(text).to include("Torre Aurora", "Replanteo", list.code, "Hierros", "Hierro 8 mm", "12,5", "barra", "Entregar en obra")
    expect(text).not_to include("9.876", "9876", "Precio", "Subtotal")
  end

  it "no explota con caracteres fuera de Windows-1252 (emoji, otros alfabetos)" do
    list.material_items.first.update!(name: "Cemento 🧱 水泥", notes: "ñandú m³ ½")

    expect { described_class.new(list).render }.not_to raise_error
    expect(pdf_text(described_class.new(list))).to include("ñandú m³ ½")
  end

  it "arma el nombre de archivo con el código y el nombre de la lista" do
    expect(described_class.new(list).filename).to eq("materiales-#{list.code.downcase}-hierros.pdf")
  end
end
