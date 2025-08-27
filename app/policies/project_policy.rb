class ProjectPolicy < ApplicationPolicy
  def show?
    user.admin? || record.owner == user || record.members.include?(user)
  end
end
