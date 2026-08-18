# frozen_string_literal: true

class ProjectPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    project_access?
  end

  def create?
    user.present? && (user.constructor? || user.admin?)
  end

  # Editar los datos de la obra (nombre, fechas, presupuesto, ubicación).
  def update?
    project_manager?
  end

  # Sólo el owner (o el admin de plataforma) borra la obra.
  def destroy?
    project_owner?
  end

  def materials?
    show?
  end

  # Editar listas de materiales de la obra.
  def manage_materials?
    project_editor?
  end

  # Cargar contenido de la obra: planos, documentos, fotos, análisis de IA.
  # Es el permiso que corresponde donde hoy se pide `:update?` sólo para subir
  # archivos — `:update?` pasó a significar "editar la obra" (admin+).
  def manage_content?
    project_editor?
  end

  # Equipo: invitar/quitar miembros y alta/baja de personas.
  def manage_team?
    project_manager?
  end

  alias_method :new?, :create?
  alias_method :edit?, :update?

  # Obras propias + donde soy miembro. El admin de plataforma ve todas: es la
  # contracara de `platform_admin?` en las policies, para que el scope y el
  # permiso digan lo mismo. Project.accessible_by, en cambio, nunca devuelve
  # todo — ahí no hay excepciones.
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.blank?
      return scope.all if user.admin?

      scope.accessible_by(user)
    end
  end
end
