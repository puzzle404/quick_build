# frozen_string_literal: true

class NotePolicy < ApplicationPolicy
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

    project = case record.noteable
    when Project      then record.noteable
    when ProjectStage then record.noteable.project
    end

    return false unless project

    user.admin? || project.owner == user
  end
end
