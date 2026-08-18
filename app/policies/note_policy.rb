# frozen_string_literal: true

class NotePolicy < ApplicationPolicy
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

  private

  # La nota cuelga de una obra o de una etapa. Un noteable de otro tipo (o
  # nil) deja project en nil y todo se deniega.
  def resolve_project
    case record.noteable
    when Project      then record.noteable
    when ProjectStage then record.noteable.project
    end
  end
end
