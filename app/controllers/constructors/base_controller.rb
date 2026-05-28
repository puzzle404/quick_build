class Constructors::BaseController < ApplicationController
  before_action :ensure_constructor!, if: -> { current_user.present? }
  helper Constructors::ProjectsHelper
  helper QuickbuildHelper

  layout :pick_constructor_layout

  # Subclasses (project show, planning, materials, etc.) set these so the
  # sidebar can render the project chip and highlight the right sub-nav.
  attr_accessor :current_qb_section, :current_qb_project, :current_qb_project_sub
  helper_method :current_qb_section, :current_qb_project, :current_qb_project_sub

  private

  # Hotwire Native and other mobile clients get the slimmer `mobile` layout
  # (large title + tab bar) instead of the desktop sidebar.
  def pick_constructor_layout
    mobile_client? ? "mobile" : "constructor"
  end

  def ensure_constructor!
    redirect_to root_path, alert: "No autorizado" unless current_user.constructor?
  end
end
