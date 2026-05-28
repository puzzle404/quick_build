class Constructors::Projects::AiAnalysesController < Constructors::BaseController
  before_action :set_project
  before_action :set_blueprint
  before_action :set_analysis, only: [:show, :apply]
  
  # POST /constructors/projects/:project_id/blueprints/:blueprint_id/ai_analyses
  def create
    authorize @project, :update?
    
    filter = params[:filter] # 'muros', 'aberturas', 'pisos_losas', or nil
    
    # Enqueue the background job
    job = AnalyzeBlueprintJob.perform_later(@blueprint.id, filter: filter)
    
    # Create a placeholder analysis record (will be updated by the job)
    @analysis = @blueprint.ai_blueprint_analyses.last || 
                @blueprint.ai_blueprint_analyses.create!(status: 'queued')
    
    respond_to do |format|
      format.html { redirect_to [@project, @blueprint], notice: "Análisis iniciado. Esto puede tomar unos segundos..." }
      format.json { render json: { success: true, analysis_id: @analysis.id, status: @analysis.status } }
    end
  end
  
  # GET /constructors/projects/:project_id/blueprints/:blueprint_id/ai_analyses/:id
  def show
    authorize @project, :show?
    
    respond_to do |format|
      format.html
      format.json { render json: @analysis }
    end
  end
  
  # POST /constructors/projects/:project_id/blueprints/:blueprint_id/ai_analyses/:id/apply
  def apply
    authorize @project, :update?
    
    unless @analysis.completed?
      return render json: { success: false, error: "Analysis not completed" }, status: :unprocessable_entity
    end
    
    # Apply selected measurements to the blueprint
    selected_indices = params[:selected_indices] || []
    
    applied_count = apply_measurements_to_blueprint(selected_indices)
    
    @analysis.mark_as_applied!
    
    respond_to do |format|
      format.html { redirect_to [@project, @blueprint], notice: "#{applied_count} mediciones aplicadas correctamente" }
      format.json { render json: { success: true, applied_count: applied_count } }
    end
  end
  
  private
  
  def set_project
    @project = current_user.projects.find(params[:project_id])
  end
  
  def set_blueprint
    @blueprint = @project.blueprints.find(params[:blueprint_id])
  end
  
  def set_analysis
    @analysis = @blueprint.ai_blueprint_analyses.find(params[:id])
  end
  
  def apply_measurements_to_blueprint(selected_indices)
    return 0 unless @analysis.suggested_measurements.present?
    
    elements = @analysis.suggested_measurements['elements'] || []
    selected_elements = selected_indices.map { |i| elements[i.to_i] }.compact
    
    # Group measurements by construction item
    groups = @blueprint.measurements['groups'] || []
    
    selected_elements.each do |element|
      # Find or create a group for this construction item
      group = find_or_create_group(groups, element)
      
      # Add measurement element to the group
      add_element_to_group(group, element)
    end
    
    # Save updated measurements
    @blueprint.update!(measurements: { groups: groups })
    
    selected_elements.count
  end
  
  def find_or_create_group(groups, element)
    # Try to find existing group with same construction item
    construction_item_name = element['construction_item']
    
    group = groups.find { |g| g['name'] == construction_item_name }
    
    unless group
      # Create new group
      group = {
        'id' => SecureRandom.uuid,
        'name' => construction_item_name,
        'construction_item_id' => nil, # TODO: match to actual ConstructionItem
        'type' => element['type'],
        'color' => generate_random_color,
        'elements' => [],
        'total_value' => 0,
        'unit' => element['unit']
      }
      groups << group
    end
    
    group
  end
  
  def add_element_to_group(group, element)
    # Create measurement element
    # Note: We don't have exact coordinates from AI, so we'll create placeholder geometry
    measurement_element = {
      'id' => SecureRandom.uuid,
      'points' => generate_placeholder_points(element['type']),
      'value' => element['estimated_value']
    }
    
    group['elements'] << measurement_element
    group['total_value'] = group['elements'].sum { |el| el['value'] }
  end
  
  def generate_placeholder_points(type)
    # Generate dummy points - user will need to adjust these manually
    case type
    when 'line'
      [{ 'x' => 100, 'y' => 100 }, { 'x' => 200, 'y' => 100 }]
    when 'polygon'
      [{ 'x' => 100, 'y' => 100 }, { 'x' => 200, 'y' => 100 }, { 'x' => 200, 'y' => 200 }, { 'x' => 100, 'y' => 200 }]
    when 'marker'
      [{ 'x' => 150, 'y' => 150 }]
    else
      []
    end
  end
  
  def generate_random_color
    colors = ['#ef4444', '#f97316', '#f59e0b', '#84cc16', '#10b981', '#06b6d4', '#3b82f6', '#6366f1', '#8b5cf6']
    colors.sample
  end
end
