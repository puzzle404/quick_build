# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Constructors::Expenses", type: :request do
  let(:owner) { create(:user, :constructor) }
  let(:other) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }
  let(:stage) { create(:project_stage, project: project) }

  let(:valid_params) do
    {
      expense: {
        amount_cents: 150_000,
        currency: "ARS",
        category: "labor",
        incurred_on: Date.today.to_s,
        description: "Jornales pintura"
      }
    }
  end

  describe "GET /constructors/projects/:project_id/expenses" do
    let!(:labor)  { create(:expense, project: project, project_stage: stage, author: owner, category: :labor,  description: "Jornales pintura", amount_cents: 100_00) }
    let!(:rental) { create(:expense, project: project, project_stage: nil,   author: owner, category: :rentals, description: "Andamio",         amount_cents: 200_00) }

    it "lista los gastos de la obra para el dueño" do
      sign_in(owner)
      get constructors_project_expenses_path(project)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Jornales pintura", "Andamio")
      expect(response.body).to include(stage.name)
    end

    it "filtra por categoría" do
      sign_in(owner)
      get constructors_project_expenses_path(project, category: "rentals")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Andamio")
      expect(response.body).not_to include("Jornales pintura")
    end

    it "filtra los gastos sin etapa" do
      sign_in(owner)
      get constructors_project_expenses_path(project, stage: "none")

      expect(response.body).to include("Andamio")
      expect(response.body).not_to include("Jornales pintura")
    end

    it "no expone la obra a un constructor ajeno" do
      sign_in(other)
      get constructors_project_expenses_path(project)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST stage-scoped /constructors/projects/:project_id/stages/:stage_id/expenses" do
    context "as project owner" do
      before { sign_in(owner) }

      it "creates the expense associated to the stage, increments count, and redirects to stage" do
        expect {
          post constructors_project_stage_expenses_path(project, stage), params: valid_params
        }.to change(Expense, :count).by(1)

        expense = Expense.last
        expect(expense.project_stage).to eq(stage)
        expect(expense.author).to eq(owner)
        expect(response).to redirect_to(constructors_project_stage_path(project, stage))
      end
    end

    context "as non-owner" do
      before { sign_in(other) }

      it "is blocked (Pundit raises) and does not create an expense" do
        expect {
          post constructors_project_stage_expenses_path(project, stage), params: valid_params
        }.not_to change(Expense, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST project-scoped /constructors/projects/:project_id/expenses" do
    context "as project owner" do
      before { sign_in(owner) }

      it "creates an expense with no stage and redirects to the project" do
        expect {
          post constructors_project_expenses_path(project), params: valid_params
        }.to change(Expense, :count).by(1)

        expense = Expense.last
        expect(expense.project).to eq(project)
        expect(expense.project_stage).to be_nil
        expect(expense.author).to eq(owner)
        expect(response).to redirect_to(constructors_project_path(project))
      end
    end

    context "as non-owner" do
      before { sign_in(other) }

      it "is blocked (project scope raises RecordNotFound) and creates nothing" do
        expect {
          post constructors_project_expenses_path(project), params: valid_params
        }.not_to change(Expense, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # Regression guard (final review, fix 1): el form vive dentro del frame
  # "drawer". Con un `redirect_to ..., alert:` en la rama de error Turbo seguía
  # el redirect como request de frame, aterrizaba en una página sin contenido
  # para "drawer" (el drawer se cerraba solo) y el alert se descartaba con esa
  # respuesta: el usuario perdía lo tipeado sin ver un mensaje.
  describe "POST inválido desde el drawer" do
    before { sign_in(owner) }

    let(:invalid_params) do
      { expense: { amount_pesos: "", currency: "ARS", category: "labor", incurred_on: Date.today.to_s } }
    end

    # Mismo Accept que manda Turbo al submitear un form dentro de un frame.
    let(:turbo_accept) { "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }

    it "re-renderiza el form dentro del drawer con 422 en vez de redirigir" do
      expect {
        post constructors_project_expenses_path(project),
             params: invalid_params,
             headers: { "Turbo-Frame" => "drawer", "Accept" => turbo_accept }
      }.not_to change(Expense, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).not_to be_redirect
      # Tiene que ser HTML, no text/vnd.turbo-stream.html: Turbo procesa una
      # respuesta turbo-stream buscando <turbo-stream> y descartaría el form.
      expect(response.media_type).to eq("text/html")
      expect(response.body).to include('id="drawer"')
      expect(response.body).to include("qb-drawer-panel")
      expect(response.body).to include("No pudimos guardar el gasto")
      expect(response.body).to include("Monto (ARS)")
    end

    it "hace lo mismo en la rama de etapa" do
      post constructors_project_stage_expenses_path(project, stage),
           params: invalid_params,
           headers: { "Turbo-Frame" => "drawer" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("qb-drawer-panel")
      expect(response.body).to include("No pudimos guardar el gasto")
    end

    it "conserva el redirect + alert cuando el POST no viene de un frame (mobile / página completa)" do
      post constructors_project_expenses_path(project), params: invalid_params

      expect(response).to redirect_to(constructors_project_path(project))
      expect(flash[:alert]).to be_present
    end
  end

  describe "GET #new sin frame" do
    before { sign_in(owner) }

    it "redirige en vez de servir una página en blanco" do
      get new_constructors_project_expense_path(project)

      expect(response).to redirect_to(constructors_project_path(project))
    end

    it "sirve el drawer cuando la request viene del frame" do
      get new_constructors_project_expense_path(project), headers: { "Turbo-Frame" => "drawer" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("qb-drawer-panel")
    end
  end

  describe "DELETE project-scoped /constructors/projects/:project_id/expenses/:id" do
    before { sign_in(owner) }

    it "destroys the expense and decrements count" do
      expense = create(:expense, project: project, author: owner)
      expect {
        delete constructors_project_expense_path(project, expense)
      }.to change(Expense, :count).by(-1)
    end

    it "vuelve al listado de gastos cuando el borrado sale de ahí" do
      expense = create(:expense, project: project, author: owner)
      delete constructors_project_expense_path(project, expense, return_to: constructors_project_expenses_path(project))

      expect(response).to redirect_to(constructors_project_expenses_path(project))
    end
  end

  describe "PATCH mark_as_paid de una lista de materiales" do
    let(:material_list) { create(:material_list, project: project, project_stage: stage, add_default_item: false) }

    before do
      create(:material_item, material_list: material_list, quantity: 3, estimated_cost_cents: 1_000_00)
      sign_in(owner)
    end

    it "registra un gasto por el total estimado y deja la lista como pagada" do
      expect {
        patch mark_as_paid_constructors_project_material_list_path(project, material_list)
      }.to change(Expense, :count).by(1)

      expense = Expense.last
      expect(expense.material_list).to eq(material_list)
      expect(expense.amount_cents).to eq(3 * 1_000_00)
      expect(expense.category).to eq("materials_misc")
      expect(expense.project_stage).to eq(stage)
      expect(expense.author).to eq(owner)
      expect(material_list.reload).to be_paid
      expect(response).to redirect_to(constructors_project_material_list_path(project, material_list))
    end

    it "no vuelve a cobrar una lista ya pagada" do
      patch mark_as_paid_constructors_project_material_list_path(project, material_list)

      expect {
        patch mark_as_paid_constructors_project_material_list_path(project, material_list)
      }.not_to change(Expense, :count)
      expect(flash[:alert]).to match(/ya figura como pagada/i)
    end

    it "no deja pagar a un constructor ajeno" do
      sign_in(other)

      expect {
        patch mark_as_paid_constructors_project_material_list_path(project, material_list)
      }.not_to change(Expense, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
end
