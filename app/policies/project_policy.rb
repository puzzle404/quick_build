class ProjectPolicy < ApplicationPolicy
  def show?
    return false unless user

    admin? || owner? || collaborator?
  end

  def create?
    user&.constructor? || admin?
  end

  def update?
    return false unless user

    admin? || owner?
  end

  def materials?
    show?
  end

  def manage_materials?
    return false unless user

    admin? || owner?
  end

  alias_method :new?, :create?
  alias_method :edit?, :update?

  private

  def admin?
    user&.admin?
  end

  def owner?
    record.owner == user
  end

  def collaborator?
    record.members.include?(user)
  end
end
