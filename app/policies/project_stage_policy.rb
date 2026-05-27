class ProjectStagePolicy < ApplicationPolicy
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
  alias_method :duplicate?, :create?
  alias_method :complete?, :update?

  private

  def manage?
    return false unless user

    user.admin? || record.project.owner == user
  end
end
