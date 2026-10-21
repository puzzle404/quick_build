# frozen_string_literal: true

# Drawer lateral para sumar a un usuario existente como miembro de la obra, con
# un rol. POSTea a project_memberships#create. Excepción documentada: no hay
# ruta :new en project_memberships, así que este componente es una instancia
# inline y autocontenida de qb--drawer en modo click-driven (sin frame target),
# no el drawer global frame-driven que usan el resto de las vistas.
class Constructors::Projects::Overview::InviteMemberDrawerComponent < ViewComponent::Base
  def initialize(project:)
    @project = project.respond_to?(:object) ? project.object : project
  end

  attr_reader :project

  # Etiquetas es-AR de los roles: fuente única en RoleBadgeComponent, para que
  # el select, la lista de miembros y el pill del header no divergan.
  def role_options
    Constructors::Projects::RoleBadgeComponent.options
  end

  # "Editor — puede cargar etapas, gastos, …" debajo del select: sin esto, elegir
  # el rol es adivinar.
  def role_hints
    Constructors::Projects::RoleBadgeComponent::ASSIGNABLE.map do |role|
      [ Constructors::Projects::RoleBadgeComponent.label_for(role),
        Constructors::Projects::RoleBadgeComponent.hint_for(role) ]
    end
  end

  # Usuarios que todavía no son miembros de esta obra — candidatos a invitar.
  # El dueño queda afuera: ya tiene acceso total por owner_id.
  def candidate_user_options
    member_ids = project.project_memberships.pluck(:user_id)
    User.where.not(id: member_ids + [ project.owner_id ]).order(:email).map { |u| [ u.email, u.id ] }
  end
end
