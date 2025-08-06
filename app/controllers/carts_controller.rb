class CartsController < ApplicationController
  def show
    @cart = current_cart
    @products = Product.where(id: @cart.keys)
  end

  def add
    product_id = params[:product_id].to_s
    cart = current_cart
    cart[product_id] = (cart[product_id] || 0) + 1
    session[:cart] = cart
  end

  def remove
    product_id = params[:product_id].to_s
    cart = current_cart
    cart.delete(product_id)
    session[:cart] = cart
    redirect_to cart_path
  end
end
