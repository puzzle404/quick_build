# frozen_string_literal: true

require "rails_helper"

# Avance, responsable, presupuesto de etapa y tarifa de persona se muestran en
# media app (card, drawer, Gantt, CSV, curva S, KPIs de equipo) pero durante
# mucho tiempo no estuvieron en strong params: el form los mandaba y el
# controller los descartaba en silencio. Estos specs son el guard de eso.
RSpec.describe "Campos de seguimiento editables", type: :request do
  let(:owner)   { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }

  before { sign_in(owner) }

  describe "PATCH etapa" do
    let(:stage) { create(:project_stage, project: project, progress: 0, budget_cents: nil) }

    it "persiste progress, lead y budget en pesos es-AR" do
      patch constructors_project_stage_path(project, stage),
            params: { project_stage: { name: stage.name, progress: "42", lead: "Ana Quiroga",
                                       budget_pesos: "1.500,50" } }

      stage.reload
      expect(stage.progress).to eq(42)
      expect(stage.lead).to eq("Ana Quiroga")
      # "1.500,50" es mil quinientos con cincuenta, no un millón y medio.
      expect(stage.budget_cents).to eq(150_050)
    end

    it "muestra los tres campos en el form de edición" do
      get edit_constructors_project_stage_path(project, stage)

      expect(response.body).to include('name="project_stage[progress]"')
      expect(response.body).to include('name="project_stage[lead]"')
      expect(response.body).to include('name="project_stage[budget_pesos]"')
    end
  end

  describe "PATCH persona" do
    let(:person) { create(:project_person, project: project, hourly_rate_cents: nil) }

    it "persiste la tarifa tipeada en pesos" do
      patch constructors_project_person_path(project, person),
            params: { project_person: { full_name: person.full_name, hourly_rate_pesos: "8.750,25" } }

      expect(person.reload.hourly_rate_cents).to eq(875_025)
    end

    it "vacía la tarifa cuando el campo se manda en blanco" do
      person.update!(hourly_rate_cents: 500_000)

      patch constructors_project_person_path(project, person),
            params: { project_person: { full_name: person.full_name, hourly_rate_pesos: "" } }

      expect(person.reload.hourly_rate_cents).to be_nil
    end
  end
end
