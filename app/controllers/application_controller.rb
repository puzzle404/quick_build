class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  
  include Authenticable
  include Pundit::Authorization
  include RolesHelper
  include Cart
  # rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
end
