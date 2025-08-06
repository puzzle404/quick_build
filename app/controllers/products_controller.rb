class ProductsController < ApplicationController
  def index
    @products = if params[:query].present?
                  Product.search_by_name(params[:query])
                else
                  Product.all
                end
  end
end
