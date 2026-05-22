class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  include Authenticable
  include Pagy::Backend
  include Pundit::Authorization
  include RolesHelper
  include Cart

  helper QuickbuildHelper
  helper Pagy::Frontend
  # rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
end
