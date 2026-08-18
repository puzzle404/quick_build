# frozen_string_literal: true

# Accesos a la obra: quiénes entran a QuickBuild a ver/cargar esta obra y con
# qué rol. Es el complemento de "Personas" (ProjectPerson = quién trabaja en la
# obra, sin usuario ni login).
#
# El dueño va primero y no se puede quitar: su acceso sale de projects.owner_id,
# no de una ProjectMembership. Quitar miembros e invitar es admin de obra en
# adelante (ProjectMembershipPolicy); el resto sólo ve la lista.
class Constructors::Projects::Overview::MembersPanelComponent < ViewComponent::Base
  def initialize(project:)
    @project = project.respond_to?(:object) ? project.object : project
  end

  attr_reader :project

  # [[user, rol, membership_or_nil], …]
  def rows
    @rows ||= begin
      list = project.owner ? [ [ project.owner, :owner, nil ] ] : []
      list + memberships.map { |m| [ m.user, m.effective_role, m ] }
    end
  end

  def memberships
    @memberships ||= project.project_memberships.includes(:user).sort_by { |m| m.user&.email.to_s }
  end

  # Invitar / quitar: ProjectMembershipPolicy#create? = admin de obra o más.
  def can_manage?
    return @can_manage if defined?(@can_manage)

    @can_manage = helpers.policy(project).manage_team?
  end

  def role_label(role)
    Constructors::Projects::RoleBadgeComponent.label_for(role)
  end

  def role_hint(role)
    Constructors::Projects::RoleBadgeComponent.hint_for(role)
  end

  def display_name(user)
    user.try(:name).presence || user.email.to_s.split("@").first.to_s.titleize
  end
end
