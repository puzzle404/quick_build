class ProjectMembershipPolicy < ApplicationPolicy
  def create?
    user.admin? || record.project.owner == user
  end

  def destroy?
    create?
  end
end
