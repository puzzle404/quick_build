class Constructors::BaseController < ApplicationController
  before_action :ensure_constructor!, if: -> { current_user.present? }
  helper Constructors::ProjectsHelper
  
  layout "constructor"

  private

  def ensure_constructor!
    redirect_to root_path, alert: "No autorizado" unless current_user.constructor?
  end
end
