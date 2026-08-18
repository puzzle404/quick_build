# frozen_string_literal: true

require "rails_helper"

# Los dos drawers de plantillas se montan en projects#show (click-driven
# qb--drawer, sin ruta #new propia — mismo patrón que
# InviteMemberDrawerComponent). El render completo es la red de seguridad: un
# `helpers.` faltante rompe la pantalla entera.
RSpec.describe "Planning template drawers", type: :component do
  include ViewComponent::TestHelpers

  let(:owner) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner, start_date: Date.new(2026, 3, 1)) }

  describe Constructors::Projects::Planning::TemplateDrawerComponent do
    it "lista la plantilla base y las guardadas por el dueño de la obra" do
      mine = create(:stage_template, owner: owner, name: "Vivienda unifamiliar")
      create(:stage_template_item, stage_template: mine, name: "Movimiento de suelos")
      create(:stage_template, owner: create(:user, :constructor), name: "Plantilla ajena")

      render_inline described_class.new(project: project)

      # Chrome de drawer (no de modal centrada): shell click-driven +
      # DrawerComponent, sin el diálogo/panel fijo de qb--modal.
      expect(page).to have_css(".qb-drawer-shell[data-qb--drawer-target='dialog']")
      expect(page).to have_css(".qb-drawer-title", text: "Aplicar plantilla de etapas")
      expect(page).to have_no_css("[data-qb--modal-target]")

      expect(page).to have_text("Plantilla base")
      expect(page).to have_text("Vivienda unifamiliar")
      expect(page).to have_text("Movimiento de suelos")
      expect(page).to have_no_text("Plantilla ajena")
      # Presupuestos apagado por defecto, fechas encendido.
      expect(page).to have_css("input[name='apply_budgets'][type='checkbox']:not([checked])", visible: :all)
      expect(page).to have_css("input[name='apply_dates'][type='checkbox'][checked]", visible: :all)
      # Cancelar cierra el drawer client-side, no navega (sin href ni _top).
      expect(page).to have_css("button[data-action='click->qb--drawer#close']", text: "Cancelar")
    end
  end

  describe Constructors::Projects::Planning::SaveTemplateDrawerComponent do
    it "confirma cuántas etapas se guardan" do
      root = create(:project_stage, project: project, name: "Estructura")
      create(:project_stage, project: project, parent: root, name: "Encofrado")

      render_inline described_class.new(project: project)

      expect(page).to have_css(".qb-drawer-shell[data-qb--drawer-target='dialog']")
      expect(page).to have_css(".qb-drawer-title", text: "Guardar como plantilla")
      expect(page).to have_text("Se guardan 1 etapa y 1 sub-etapa")
      expect(page).to have_field("stage_template[name]", with: "Plantilla · #{project.name}", visible: :all)
      expect(page).to have_css("button[data-action='click->qb--drawer#close']", text: "Cancelar")
    end

    it "bloquea el guardado cuando la obra no tiene etapas" do
      render_inline described_class.new(project: project)

      expect(page).to have_text("todavía no tiene etapas cargadas")
      expect(page).to have_no_css("form")
      expect(page).to have_css("button[data-action='click->qb--drawer#close']", text: "Entendido")
    end
  end
end
