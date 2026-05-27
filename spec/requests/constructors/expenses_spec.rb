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
  end
end
