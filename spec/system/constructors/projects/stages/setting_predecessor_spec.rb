# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Setting stage predecessor", type: :system do
  let(:owner)   { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }
  let!(:fundaciones) do
    create(:project_stage, project: project, name: "Fundaciones",
           start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 15))
  end

  before { sign_in_user(owner) }

  it "permite elegir predecesora con fechas válidas" do
    visit new_constructors_project_stage_path(project)

    fill_in "Nombre de la etapa", with: "Albañilería"
    fill_in "Fecha de inicio", with: "2026-01-15"
    fill_in "Fecha de finalización", with: "2026-02-15"
    select "Fundaciones", from: "Etapa predecesora"
    click_button "Guardar etapa"

    expect(page).to have_text("Albañilería")
    new_stage = project.project_stages.find_by(name: "Albañilería")
    expect(new_stage.predecessor).to eq(fundaciones)
  end

  it "muestra error si la fecha es anterior al fin de la predecesora" do
    visit new_constructors_project_stage_path(project)

    fill_in "Nombre de la etapa", with: "Mal ordenada"
    fill_in "Fecha de inicio", with: "2026-01-05"
    fill_in "Fecha de finalización", with: "2026-01-20"
    select "Fundaciones", from: "Etapa predecesora"
    click_button "Guardar etapa"

    expect(page).to have_text("no puede ser anterior al fin de la etapa predecesora")
  end
end
