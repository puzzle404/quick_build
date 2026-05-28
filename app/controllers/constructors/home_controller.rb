class Constructors::HomeController < Constructors::BaseController
  def index
    @products = Product.all
  end
end
