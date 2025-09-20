class HomeController < ApplicationController
  def index
    if current_user&.constructor?
      redirect_to constructors_root_path and return
    else
      @products = Product.all
    end
  end
end
