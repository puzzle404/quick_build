class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cart, only: [:new, :create]

  def index
    @orders = current_user.orders.includes(line_items: :product)
  end

  def show
    @order = current_user.orders.includes(line_items: :product).find(params[:id])
  end

  def new
    @order = current_user.orders.new
    @products = Product.where(id: @cart.keys)
  end

  def create
    @order = current_user.orders.new(state: 'pending')
    @cart.each do |product_id, quantity|
      @order.line_items.build(product_id: product_id, quantity: quantity)
    end
    if @order.save
      session[:cart] = {}
      redirect_to @order, notice: 'Order was successfully created.'
    else
      @products = Product.where(id: @cart.keys)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_cart
    @cart = session[:cart] || {}
  end
end
