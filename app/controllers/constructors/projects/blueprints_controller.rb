class Constructors::Projects::BlueprintsController < Constructors::BaseController
  before_action :set_project
  before_action :set_blueprint, only: [:show, :update_scale, :update_measurements, :destroy]

  def index
    authorize @project, :show?
    @blueprints = @project.blueprints.order(created_at: :desc)
  end

  def new
    authorize @project, :update?
    @blueprint = @project.blueprints.build
  end

  def create
    authorize @project, :update?
    @blueprint = @project.blueprints.build(blueprint_params)

    if @blueprint.save
      redirect_to constructors_project_blueprints_path(@project), 
                  notice: "Plano subido correctamente."
    else
      flash.now[:alert] = "Revisa los datos y vuelve a intentarlo."
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authorize @project, :show?
  end

  def update_scale
    authorize @project, :update?
    
    if @blueprint.update(scale_params)
      render json: { 
        success: true, 
        scale_ratio: @blueprint.scale_ratio,
        message: "Escala definida correctamente" 
      }
    else
      render json: { 
        success: false, 
        errors: @blueprint.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end

  def update_measurements
    authorize @project, :update?
    
    if @blueprint.update(measurements_params)
      render json: { success: true, message: "Mediciones guardadas" }
    else
      render json: { success: false, errors: @blueprint.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @project, :update?
    @blueprint.destroy
    redirect_to constructors_project_blueprints_path(@project), 
                notice: "Plano eliminado correctamente."
  end

  private

  def set_project
    @project = current_user.owned_projects.find(params[:project_id])
  end

  def set_blueprint
    @blueprint = @project.blueprints.find(params[:id])
  end

  def blueprint_params
    params.require(:blueprint).permit(:name, :description, :file)
  end

  def scale_params
    params.require(:blueprint).permit(:scale_ratio)
  end

  def measurements_params
    params.require(:blueprint).permit(measurements: { items: [:id, :type, :value, :unit, :label, point: [:x, :y], points: [:x, :y]] })
  end
end
