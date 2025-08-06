class ProductsController < ApplicationController
  before_action :set_company, only: %i[new edit update destroy]
  before_action :set_product_companies, only: %i[edit update destroy]
  before_action :set_product, only: %i[show]

  # GET /companies/:company_id/products
  def index
    @products = if params[:query].present?
                  @company.products.search_by_name(params[:query])
                else
                  @company.products
                end
  end

  # GET /companies/:company_id/products/:id
  def show
  end

  # GET /companies/:company_id/products/new
  def new
    @product = @company.products.new
  end

  # POST /companies/:company_id/products
  def create
    @product = @company.products.new(product_params)
    if @product.save
      redirect_to [@company, @product], notice: 'Product was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /companies/:company_id/products/:id/edit
  def edit
  end

  # PATCH/PUT /companies/:company_id/products/:id
  def update
    if @product.update(product_params)
      redirect_to [@company, @product], notice: 'Product was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /companies/:company_id/products/:id
  def destroy
    @product.destroy
    redirect_to company_products_path(@company), notice: 'Product was successfully destroyed.'
  end

  private

  def set_company
    @company = Company.find(params[:company_id])
  end

  def set_product
    @product = Product.find(params[:id])
  end

  def set_product_companies
    @product = @company.products.find(params[:id])
  end

  def product_params
    params.require(:product)
          .permit(:name, :price_cents, :description, :category_id, images: [])
  end
end
