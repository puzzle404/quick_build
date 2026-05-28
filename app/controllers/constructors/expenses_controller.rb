# frozen_string_literal: true

module Constructors
  class ExpensesController < Constructors::BaseController
    before_action :set_project
    before_action :set_stage, only: [ :new, :create, :destroy ]

    # Renders the mobile expense form. Desktop opens the same form inline via
    # the `qb--modal` Stimulus controller; the Native shell can't host that
    # modal, so it loads `/new` instead — the path-config rule routes it as a
    # bottom-sheet automatically.
    def new
      authorize @project, :show?
      @expense = @project.expenses.build(currency: 'ARS', incurred_on: Date.current, project_stage: @stage)
    end

    def create
      @expense = @project.expenses.new(expense_params)
      @expense.project_stage = @stage if @stage
      @expense.author = current_user
      authorize @expense

      if @expense.save
        redirect_to redirect_path, notice: "Gasto registrado correctamente."
      else
        redirect_to redirect_path,
          alert: @expense.errors.full_messages.to_sentence
      end
    end

    def destroy
      @expense = @project.expenses.find(params[:id])
      authorize @expense

      @expense.destroy
      redirect_to redirect_path, notice: "Gasto eliminado."
    end

    private

    def set_project
      @project = current_user.owned_projects.find(params[:project_id])
    end

    def set_stage
      return unless params[:stage_id].present?

      @stage = @project.project_stages.find(params[:stage_id])
    end

    def expense_params
      params.require(:expense).permit(
        :amount_cents, :currency, :category, :incurred_on, :description, :receipt
      )
    end

    def redirect_path
      if @stage
        constructors_project_stage_path(@project, @stage)
      else
        constructors_project_path(@project)
      end
    end
  end
end
