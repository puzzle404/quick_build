class CartsController < ApplicationController
  after_action :set_session_cart, only: [:add, :remove]
  
  def show
    @products = Product.where(id: cart.keys)
  end

  def add
    cart[product_id] = (cart[product_id] || 0) + 1
    turbo_stream_response
  end

  def remove
    cart.delete(product_id)
    redirect_to cart_path
  end
  
  private

  def product_id
    @product_id = params[:product_id].to_s
  end

  def cart
    @cart = current_cart
  end

  def set_session_cart
    session[:cart] = cart
  end

  def turbo_stream_response
    respond_to do |format|
      format.turbo_stream
    end
  end

  def process_turbo_stream_response
    turbo_stream_response
  end
end
