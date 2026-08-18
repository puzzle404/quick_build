class PagesController < ApplicationController
  # Páginas estáticas públicas (marketing/legal), no requieren autenticación.
  allow_unauthenticated_access
  layout "marketing"

  # allow_unauthenticated_access saltea require_authentication, así que
  # reanudamos la sesión manualmente para que la navbar refleje al usuario.
  before_action :resume_session

  def terms; end

  def privacy; end

  def pricing; end
end
