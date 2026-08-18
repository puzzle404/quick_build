class Constructors::BaseController < ApplicationController
  before_action :ensure_constructor!, if: -> { current_user.present? }
  helper Constructors::ProjectsHelper
  helper QuickbuildHelper

  layout :pick_constructor_layout

  # Sin esto, cada denegación de Pundit terminaba en un 500. Hay dos formas de
  # decir "no" y NO son intercambiables:
  #
  #   404 → la obra no está en `accessible_projects`: `find_project!` levanta
  #         RecordNotFound antes de llegar a Pundit. No confirmamos ni la
  #         existencia de obras ajenas.
  #   403 → estás adentro de la obra pero tu rol no alcanza (un viewer que
  #         intenta cargar un gasto). En HTML se traduce a "volver con alert",
  #         que es lo que espera un usuario logueado.
  rescue_from Pundit::NotAuthorizedError, with: :qb_access_denied

  # Subclasses (project show, planning, materials, etc.) set these so the
  # sidebar can render the project chip and highlight the right sub-nav.
  attr_accessor :current_qb_section, :current_qb_project, :current_qb_project_sub
  helper_method :current_qb_section, :current_qb_project, :current_qb_project_sub

  private

  # Punto ÚNICO de entrada a una obra desde la URL. Busca dentro de lo que el
  # usuario puede ver —las propias (owner_id) más aquellas donde es miembro— y
  # deja el resultado en @project.
  #
  # Nunca `Project.find` a secas (filtra obras de otros constructores) ni
  # `current_user.owned_projects` (dejaba a los miembros afuera: las membresías
  # eran decorativas). El scope decide si entrás; QUÉ podés hacer adentro lo
  # decide Pundit sobre @project.
  #
  # `id:` cubre el caso donde el id no viaja en un param de la ruta sino
  # anidado en el form (stage_templates).
  def find_project!(param = :project_id, id: params[param])
    @project = current_user.accessible_projects.find(id)
  end

  # Hotwire Native and other mobile clients get the slimmer `mobile` layout
  # (large title + tab bar) instead of the desktop sidebar.
  def pick_constructor_layout
    mobile_client? ? "mobile" : "constructor"
  end

  def ensure_constructor!
    redirect_to root_path, alert: "No autorizado" unless current_user.constructor?
  end

  def qb_access_denied(_exception = nil)
    message = "No tenés permiso para hacer esto en esta obra."

    respond_to do |format|
      format.html do
        if request.get?
          redirect_to qb_denied_fallback_path, alert: message
        else
          redirect_back fallback_location: qb_denied_fallback_path, alert: message, status: :see_other
        end
      end
      format.turbo_stream do
        redirect_back fallback_location: qb_denied_fallback_path, alert: message, status: :see_other
      end
      format.json { render json: { error: message }, status: :forbidden }
      format.any  { head :forbidden }
    end
  end

  # A dónde vuelve el usuario después de un "no". Si la obra ya está resuelta
  # es porque pasó por `find_project!`, así que puede verla y no hay loop de
  # redirects posible; si no, al dashboard.
  def qb_denied_fallback_path
    return constructors_project_path(@project) if @project.respond_to?(:id) && @project.id.present?

    constructors_root_path
  end
end
