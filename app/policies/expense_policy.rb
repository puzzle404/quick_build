# frozen_string_literal: true

class ExpensePolicy < ApplicationPolicy
  # Ver gastos alcanza con acceso a la obra; cargarlos/borrarlos es de editor.
  def index?
    project_access?
  end

  def show?
    project_access?
  end

  def create?
    project_editor?
  end

  def update?
    project_editor?
  end

  def destroy?
    project_editor?
  end

  alias_method :new?, :create?
  alias_method :edit?, :update?
end
