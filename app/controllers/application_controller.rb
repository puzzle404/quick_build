class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :current_cart
  helper_method :cart_items_count

  protected

  def configure_permitted_parameters
    added_attrs = %i[address phone name role company_id]
    devise_parameter_sanitizer.permit(:sign_up, keys: added_attrs)
    devise_parameter_sanitizer.permit(:account_update, keys: added_attrs)
  end

  private

  def current_cart
    session[:cart] ||= {}
  end

  def cart_items_count
    current_cart.values.sum
  end
end
