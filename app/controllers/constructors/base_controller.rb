class Constructors::BaseController < ApplicationController
  layout "constructor"
  before_action :authenticate_user!
  before_action :ensure_constructor!, if: -> { current_user.present? }

  private

  def ensure_constructor!
    redirect_to root_path, alert: "No autorizado" unless current_user.constructor?
  end
end