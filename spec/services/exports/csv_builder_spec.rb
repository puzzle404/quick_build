# frozen_string_literal: true

require "rails_helper"

RSpec.describe Exports::CsvBuilder do
  it "emite el dialecto único: BOM, separador ';' y CRLF" do
    csv = described_class.generate([ "Código", "Obra" ]) do |rows|
      rows << [ "PRJ-001", "Torre Azul" ]
    end

    expect(csv.bytes.first(3)).to eq([ 0xEF, 0xBB, 0xBF ])
    expect(csv).to include("Código;Obra\r\n")
    expect(csv).to include("PRJ-001;Torre Azul\r\n")
  end

  it "formatea plata con coma decimal, fechas dd/mm/aaaa y porcentajes sin '%'" do
    expect(described_class.cents(8_450_000_012)).to eq("84500000,12")
    expect(described_class.cents(-1234)).to eq("-12,34")
    expect(described_class.amount(1234.5)).to eq("1234,50")
    expect(described_class.number(420.0)).to eq("420")
    expect(described_class.number(12.5)).to eq("12,5")
    expect(described_class.percent(45.6)).to eq("46")
    expect(described_class.date(Date.new(2025, 11, 28))).to eq("28/11/2025")
  end

  it "deja la celda vacía para nil y para strings en blanco" do
    csv = described_class.generate([ "A", "B", "C" ]) do |rows|
      rows << [ nil, "", "  " ]
    end

    expect(csv.lines.last).to eq(";;\r\n")
  end

  it "neutraliza fórmulas sin romper los números negativos" do
    csv = described_class.generate([ "Obra", "Saldo" ]) do |rows|
      rows << [ "=1+1", described_class.cents(-500) ]
    end

    expect(csv.lines.last).to eq("'=1+1;-5,00\r\n")
  end
end
