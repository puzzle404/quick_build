# frozen_string_literal: true

# Equipo de la obra: invitar y quitar miembros. Sólo admin de obra u owner
# (ProjectMembershipPolicy → project_manager?).
#
# Antes colgaba de ApplicationController y buscaba con `Project.find` a secas:
# cualquier constructor logueado podía POSTear contra la obra de otro y comerse
# un 500 de Pundit en vez de un 404. Ahora hereda de la base del namespace
# (mismo layout, mismo manejo de denegaciones) y entra por `find_project!`.
class Constructors::ProjectMembershipsController < Constructors::BaseController
  before_action :find_project!

  def create
    # El permiso se chequea ANTES que la forma del payload: a quien no puede
    # invitar le tiene que contestar "no tenés permiso", no "el rol es inválido".
    @membership = @project.project_memberships.new(user_id: params.dig(:project_membership, :user_id))
    authorize @membership

    role = requested_role
    return redirect_back_to_project(alert: "Elegí un rol válido para el miembro.") if role.nil?

    @membership.role = role

    # El owner no tiene membresía: su acceso sale de projects.owner_id. Una
    # membresía suya sería ruido que además podría "degradarlo" en la UI.
    return redirect_back_to_project(alert: "El dueño de la obra ya tiene acceso total.") if owner_target?(@membership.user_id)

    if @membership.save
      # El rol se memoiza por request; si el que invita se agregó a sí mismo el
      # cache viejo mentiría en el render siguiente.
      current_user.reset_project_role_cache!
      redirect_back_to_project(notice: "Sumamos a #{member_label(@membership.user)} al equipo de la obra.")
    else
      redirect_back_to_project(alert: membership_error_message)
    end
  end

  def destroy
    @membership = @project.project_memberships.find(params[:id])
    authorize @membership

    # Cinturón y tirantes: hoy el owner no tiene membresía, pero si quedó una
    # fila vieja apuntándolo, borrarla no puede leerse como "sacar al dueño".
    return redirect_back_to_project(alert: "No podés quitar al dueño de la obra.") if owner_target?(@membership.user_id)

    member = @membership.user
    @membership.destroy
    current_user.reset_project_role_cache!
    redirect_back_to_project(notice: "Quitamos a #{member_label(member)} del equipo de la obra.")
  end

  private

  # Whitelist explícita: `role` viene del form y el enum levanta ArgumentError
  # (500) con cualquier valor raro. Vacío = viewer, el rol más bajo.
  def requested_role
    raw = params.dig(:project_membership, :role).to_s.strip
    return ProjectMembership::DEFAULT_ROLE.to_s if raw.blank?

    ProjectMembership::ROLES.key?(raw.to_sym) ? raw : nil
  end

  def owner_target?(user_id)
    user_id.present? && user_id.to_i == @project.owner_id
  end

  # `users` no tiene columna de nombre (ni first_name/last_name): el email es
  # lo único identificable que hay.
  def member_label(user)
    user&.email.presence || "el miembro"
  end

  def membership_error_message
    @membership.errors.full_messages.to_sentence.presence || "No pudimos sumar al miembro."
  end

  def redirect_back_to_project(**flash_opts)
    redirect_to constructors_project_path(@project), **flash_opts
  end
end
