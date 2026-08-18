class Constructors::Projects::MaterialLists::MaterialItemsController < Constructors::BaseController
  before_action :find_project!
  before_action :decorate_project
  before_action :set_material_list
  before_action :load_material_items
  before_action :set_material_item, only: :destroy

  def create
    authorize @material_list, :update?
    @material_item = @material_list.material_items.build(material_item_params)

    # En mobile el show no tiene los targets de turbo_stream del desktop
    # (ids de la tabla), así que respondemos con redirect + flash.
    if request.variant.include?(:mobile)
      if @material_item.save
        redirect_to constructors_project_material_list_path(@project, @material_list),
                    notice: "Material agregado a la lista."
      else
        redirect_to constructors_project_material_list_path(@project, @material_list),
                    alert: "No pudimos agregar el material. Revisá los datos."
      end
      return
    end

    respond_to do |format|
      if @material_item.save
        @material_items = @material_list.material_items.order(created_at: :desc)
        @material_item = @material_list.material_items.build
        format.turbo_stream
        format.html do
          redirect_to constructors_project_material_list_path(@project, @material_list),
                      notice: "Material agregado a la lista."
        end
      else
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html do
          flash[:alert] = "No pudimos agregar el material. Revisá los datos."
          redirect_to constructors_project_material_list_path(@project, @material_list)
        end
      end
    end
  end

  def destroy
    authorize @material_list, :update?
    @material_item.destroy
    @material_items = @material_list.material_items.order(created_at: :desc)
    @material_item = @material_list.material_items.build

    # Mismo criterio que en create: mobile no tiene los targets del desktop.
    if request.variant.include?(:mobile)
      redirect_to constructors_project_material_list_path(@project, @material_list),
                  notice: "Material eliminado de la lista."
      return
    end

    respond_to do |format|
      format.turbo_stream
      format.html do
        redirect_to constructors_project_material_list_path(@project, @material_list),
                    notice: "Material eliminado de la lista."
      end
    end
  end

  private

  def decorate_project
    @project = @project.decorate
  end

  def set_material_list
    @material_list = @project.material_lists.find(params[:material_list_id])
  end

  def load_material_items
    @material_items = @material_list.material_items.order(created_at: :desc)
  end

  def set_material_item
    @material_item = @material_list.material_items.find(params[:id])
  end

  def material_item_params
    params.require(:material_item).permit(:name, :description, :quantity, :unit, :estimated_cost_cents, :confidence_label, :notes)
  end
end
