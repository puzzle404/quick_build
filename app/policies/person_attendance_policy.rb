# frozen_string_literal: true

class PersonAttendancePolicy < ApplicationPolicy
  def index?
    project_access?
  end

  def show?
    project_access?
  end

  # Marcar el presente de alguien del equipo es carga de datos de obra: editor.
  def create?
    project_editor?
  end

  # Cargar las horas sobre una marca que ya existe es la misma carga de datos
  # de obra que marcarla. No se separa en otro permiso: quien puede dar el
  # presente puede completar la jornada.
  def update?
    project_editor?
  end

  def destroy?
    project_editor?
  end

  alias_method :new?, :create?

  private

  def resolve_project
    record.project_person&.project
  end
end
