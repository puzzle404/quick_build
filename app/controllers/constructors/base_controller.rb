class Constructors::BaseController < ApplicationController
  before_action :ensure_constructor!, if: -> { current_user.present? }
  helper Constructors::ProjectsHelper
  helper QuickbuildHelper

  layout "constructor"

  # Subclasses (project show, planning, materials, etc.) set these so the
  # sidebar can render the project chip and highlight the right sub-nav.
  attr_accessor :current_qb_section, :current_qb_project, :current_qb_project_sub
  helper_method :current_qb_section, :current_qb_project, :current_qb_project_sub

  private

  def ensure_constructor!
    redirect_to root_path, alert: "No autorizado" unless current_user.constructor?
  end
end
