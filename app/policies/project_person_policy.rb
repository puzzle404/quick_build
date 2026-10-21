# frozen_string_literal: true

class ProjectPersonPolicy < ApplicationPolicy
  def index?
    project_access?
  end

  def show?
    project_access?
  end

  # Alta/baja y edición de personas = gestionar el equipo: admin de la obra.
  def create?
    project_manager?
  end

  def update?
    project_manager?
  end

  def destroy?
    project_manager?
  end

  alias_method :new?, :create?
  alias_method :edit?, :update?
end
