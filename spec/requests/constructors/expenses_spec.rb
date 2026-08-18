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
