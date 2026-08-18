class Constructors::Projects::BlueprintsController < Constructors::BaseController
  before_action :find_project!
  before_action :set_blueprint, only: [ :show, :update_scale, :update_measurements, :destroy ]

  # Planos es UNA sola vista: lista + visor real (canvas, escala, mediciones) +
  # panel de IA. `?selected=:id` elige qué plano se abre en el visor.
  def index
    authorize @project, :show?
    @current_qb_section = :projects
    @project = @project.decorate
    @current_qb_project = @project
    @current_qb_project_sub = :blueprints
    # includes: status_label/analysis? del workspace leen los análisis de cada
    # plano; sin preload era una query por fila.
    @blueprints = @project.blueprints.includes(:ai_blueprint_analyses).with_attached_file.order(created_at: :desc)
    @selected_blueprint = @blueprints.find_by(id: params[:selected]) || @blueprints.first
    # Lo consume el modal "¿Qué vas a medir?" del visor (antes se cargaba en #show).
    @construction_items = @selected_blueprint ? construction_items_by_category : {}
  end

  def new
    # Planos = contenido de obra: `manage_content?` (editor+). Con `:update?`
    # (que ahora significa "editar los datos de la obra", admin+) un editor no
    # podía subir un plano, contra lo que dice la matriz.
    authorize @project, :manage_content?
    @current_qb_section = :projects
    @current_qb_project = @project.decorate
    @current_qb_project_sub = :blueprints
    @blueprint = @project.blueprints.build
  end

  def create
    authorize @project, :manage_content?
    @blueprint = @project.blueprints.build(blueprint_params)

    if @blueprint.save
      respond_to do |format|
        format.turbo_stream do
          if request.variant.include?(:mobile)
            redirect_to constructors_project_blueprints_path(@project, selected: @blueprint.id),
                        notice: "Plano subido correctamente."
          else
            flash[:notice] = "Plano subido correctamente."
            render turbo_stream: turbo_stream.refresh(request_id: nil)
          end
        end
        format.html do
          redirect_to constructors_project_blueprints_path(@project, selected: @blueprint.id),
                      notice: "Plano subido correctamente."
        end
      end
    else
      flash.now[:alert] = "Revisá los datos y volvé a intentarlo."
      render :new, status: :unprocessable_entity
    end
  end

  # En desktop el visor vive en #index, así que /blueprints/:id redirige a la
  # vista única con ese plano seleccionado. Los links viejos (historial de IA,
  # marcadores del navegador) siguen funcionando.
  # Mobile conserva su propia pantalla de detalle (show.html+mobile.erb).
  def show
    authorize @project, :show?
    return if mobile_variant?

    redirect_to constructors_project_blueprints_path(@project, selected: @blueprint.id)
  end

  def update_scale
    authorize @project, :manage_content?

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
    authorize @project, :manage_content?

    if @blueprint.update(measurements_params)
      render json: { success: true, message: "Mediciones guardadas" }
    else
      render json: { success: false, errors: @blueprint.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @project, :manage_content?
    @blueprint.destroy
    redirect_to constructors_project_blueprints_path(@project),
                notice: "Plano eliminado correctamente."
  end

  private

  def set_blueprint
    @blueprint = @project.blueprints.find(params[:id])
  end

  # { "Mampostería" => [#<ConstructionItem id:, name:, unit:, category:>, ...] }
  # El JS del visor hace Object.entries() sobre esto para armar el modal de
  # "¿Qué vas a medir?".
  def construction_items_by_category
    ConstructionItem.select(:id, :name, :unit, :category).group_by(&:category)
  end

  def blueprint_params
    params.require(:blueprint).permit(:name, :description, :file)
  end

  def scale_params
    params.require(:blueprint).permit(:scale_ratio)
  end

  def measurements_params
    params.require(:blueprint).permit(measurements: { groups: [ :id, :name, :construction_item_id, :type, :color, :total_value, :unit, elements: [ :id, :value, point: [ :x, :y ], points: [ :x, :y ] ] ] })
  end
end
