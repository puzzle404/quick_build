class Constructors::DashboardController < Constructors::BaseController
  def index
    months = params[:months].to_i
    months = 6 unless [6, 12].include?(months)
    
    @months_selected = months
    service = Constructors::DashboardService.new(current_user)
    
    @dashboard = {
      metrics: service.send(:metrics_data),
      recent_activity: service.send(:recent_activity_entries),
      upcoming_stages: service.send(:upcoming_stages_list),
      recent_documents: service.send(:recent_documents_list),
      recent_projects: service.send(:recent_projects_list),
      evolution: service.send(:evolution_data, months_count: months)
    }
  end

  # Turbo Frame endpoint for chart section
  def evolution_chart
    months = params[:months].to_i
    months = 6 unless [6, 12].include?(months)
    
    @months_selected = months
    service = Constructors::DashboardService.new(current_user)
    @evolution = service.send(:evolution_data, months_count: months)
    
    render partial: 'evolution_chart_frame', locals: { evolution: @evolution, selected_months: @months_selected }
  end
end
