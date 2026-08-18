# frozen_string_literal: true

# Chips compactos (avatar + nombre corto + rol) con los USUARIOS que tienen
# acceso a la obra: el dueño primero y después las membresías.
#
# Antes recibía `members:` (User) y mostraba `user.role`, que es el rol de
# PLATAFORMA: decía "Constructor" para todo el mundo, incluido un lector. El rol
# que importa acá es el de la obra, y ese vive en la membresía / en owner_id.
class Constructors::Projects::Overview::TeamChipsComponent < ViewComponent::Base
  def initialize(project:, limit: 6)
    @project = project
    @limit = limit
  end

  attr_reader :project, :limit

  # [[user, rol], …] — el dueño no tiene ProjectMembership, se agrega a mano.
  def entries
    @entries ||= begin
      owner = project.owner
      rows = owner ? [ [ owner, :owner ] ] : []
      rows += project.project_memberships.includes(:user).map { |m| [ m.user, m.effective_role ] }
      rows.reject { |user, _role| user.nil? }.first(limit)
    end
  end

  def total_count
    @total_count ||= (project.owner_id.present? ? 1 : 0) + project.project_memberships.size
  end

  def hidden_count
    [ total_count - entries.size, 0 ].max
  end

  def short_name(user)
    name = user.try(:name).presence || user.try(:full_name).presence || user.email.to_s.split("@").first
    name = name.to_s.split("@").first.titleize
    parts = name.split
    return name if parts.size < 2

    "#{parts.first} #{parts[1][0]}."
  end

  def role_label(role)
    Constructors::Projects::RoleBadgeComponent.label_for(role)
  end
end
