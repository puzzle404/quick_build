# frozen_string_literal: true

# Base de todas las policies. Concentra la matriz de permisos por obra para
# que ninguna policy hija tenga que repetirla:
#
#   viewer → ve toda la obra (resumen, etapas, materiales, planos, documentos,
#            equipo, gastos). No crea ni edita nada.
#   editor → viewer + crear/editar/borrar etapas, cargar gastos, editar listas
#            de materiales, subir planos/documentos/fotos, marcar asistencia,
#            escribir notas.
#   admin  → editor + editar los datos de la obra + gestionar el equipo
#            (invitar/quitar miembros, alta/baja de personas).
#   owner  → admin + borrar la obra. Nunca pierde acceso.
#
# El admin de plataforma (User#admin?) mantiene el acceso total que ya tenía.
#
# Cada policy resuelve la obra de su record con #resolve_project. Si no la
# puede resolver, `project` queda en nil y todo se deniega (fail closed).
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end
  end

  private

  # ─── Niveles de la matriz ───────────────────────────────────────
  # Nombrados por el piso que exigen: project_access? = viewer o más.

  def platform_admin?
    user.present? && user.admin?
  end

  def project_access?
    platform_admin? || project_role.present?
  end

  def project_editor?
    platform_admin? || role_at_least?(:editor)
  end

  # "admin de la obra", no el de la plataforma.
  def project_manager?
    platform_admin? || role_at_least?(:admin)
  end

  def project_owner?
    platform_admin? || project_role == :owner
  end

  # ─── Resolución de la obra y el rol ─────────────────────────────

  def project_role
    return @project_role if defined?(@project_role)

    @project_role = (project.role_for(user) if user && project)
  end

  def role_at_least?(level)
    role = project_role
    return false if role.nil?

    Project::ROLE_RANK.fetch(role, 0) >= Project::ROLE_RANK.fetch(level)
  end

  def project
    return @project if defined?(@project)

    @project = resolve_project
  end

  # Las policies con records anidados (Note → noteable, PersonAttendance →
  # project_person) sobreescriben esto.
  def resolve_project
    case record
    when Project then record
    else record.project if record.respond_to?(:project)
    end
  end
end
