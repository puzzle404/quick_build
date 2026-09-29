# frozen_string_literal: true

class MaterialListPolicy < ApplicationPolicy
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

  # Publicar/despublicar la lista en el marketplace: es parte de trabajar la
  # lista, así que va con editor.
  def toggle_publication?
    project_editor?
  end

  alias_method :new?, :create?
  alias_method :edit?, :update?
end
