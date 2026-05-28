class PersonAttendancePolicy < ApplicationPolicy
  def create?
    project_access?
  end

  private

  def project_access?
    return false unless user
    project = record.project_person.project
    user.admin? || project.owner == user || project.members.include?(user)
  end
end

