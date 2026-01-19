class ProjectPersonPolicy < ApplicationPolicy
  def index?
    project_access?
  end

  def show?
    project_access?
  end

  def create?
    manage?
  end

  def update?
    manage?
  end

  def destroy?
    manage?
  end

  alias_method :new?, :create?
  alias_method :edit?, :update?

  private

  def manage?
    return false unless user
    user.admin? || owner?
  end

  def owner?
    record.project.owner == user
  end

  def project_access?
    return false unless user
    user.admin? || record.project.owner == user || record.project.members.include?(user)
  end
end

