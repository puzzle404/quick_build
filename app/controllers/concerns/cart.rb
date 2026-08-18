module Cart
  extend ActiveSupport::Concern

  included do
    helper_method :current_cart
    helper_method :cart_items_count
  end

  def current_cart
    session[:cart] ||= {}
  end

  def cart_items_count
    current_cart.values.sum
  end
end