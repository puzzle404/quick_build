class Constructors::Projects::MaterialListsController < Constructors::BaseController
  before_action :set_project
  before_action :decorate_project
  before_action :set_material_list, only: %i[show edit update destroy toggle_publication]

  def index
    authorize @project, :materials?
    @material_lists = @project.material_lists.includes(:material_list_publication).order(updated_at: :desc)
  end

  def show
    authorize @material_list
    @material_item = @material_list.material_items.build
    @material_items = @material_list.material_items.order(created_at: :desc)
  end

  def new
    authorize @project, :manage_materials?
    @material_list = @project.material_lists.build(author: current_user)
  end

  def create
    authorize @project, :manage_materials?
    @material_list = @project.material_lists.build(material_list_params.merge(author: current_user))

    if @material_list.save
      redirect_to constructors_project_material_list_path(@project, @material_list),
                  notice: "Lista de materiales creada correctamente."
    else
      flash.now[:alert] = "No pudimos crear la lista. Revisá los datos e intentá nuevamente."
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @material_list
  end

  def update
    authorize @material_list

    if @material_list.update(material_list_params)
      redirect_to constructors_project_material_list_path(@project, @material_list),
                  notice: "Actualizamos la lista de materiales."
    else
      flash.now[:alert] = "No pudimos guardar los cambios. Revisá los datos e intentá nuevamente."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @material_list
    @material_list.destroy

    redirect_to constructors_project_material_lists_path(@project),
                notice: "Lista de materiales eliminada."
  end

  def toggle_publication
    authorize @material_list, :toggle_publication?

    publication = @material_list.material_list_publication ||
                  @material_list.build_material_list_publication

    if publication.visibility_public?
      publication.unpublish!
      message = "La lista ya no está habilitada para presupuestar."
    else
      publication.publish!
      message = "La lista quedó disponible para presupuestar."
    end

    redirect_to constructors_project_material_list_path(@project, @material_list), notice: message
  end

  private

  def set_project
    @project = current_user.owned_projects.find(params[:project_id])
  end

  def decorate_project
    @project = @project.decorate
  end

  def set_material_list
    @material_list = @project.material_lists.includes(:material_items).find(params[:id])
  end

  def material_list_params
    params.require(:material_list).permit(
      :name,
      :notes,
      :status,
      :source_type,
      :source_file
    )
  end
end
