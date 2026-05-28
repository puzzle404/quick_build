# frozen_string_literal: true

class ExpensePolicy < ApplicationPolicy
  def create?
    manage?
  end

  def destroy?
    manage?
  end

  alias_method :new?, :create?

  private

  def manage?
    return false unless user

    user.admin? || record.project.owner == user
  end
end
