# frozen_string_literal: true

class ProjectStagePolicy < ApplicationPolicy
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
  alias_method :duplicate?, :create?
  alias_method :complete?, :update?
end
