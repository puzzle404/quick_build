class ProductsController < ApplicationController
  before_action :set_company, only: %i[index show new edit update destroy]
  before_action :set_product, except: %i[index new create all_products]

  # GET /companies/:company_id/products
  def index
    @products = if params[:query].present?
                  @company.products.search_by_name(params[:query])
                else
                  @company.products
                end
  end

  def all_products
    @products = Product.all
    @products = @products.search_by_name(params[:query]) if params[:query].present?
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

  def set_products_company
    @product = @company.products.find(params[:id])
  end

  def product_params
    params.require(:product)
          .permit(:name, :price_cents, :description, :category_id, images: [])
  end
end
