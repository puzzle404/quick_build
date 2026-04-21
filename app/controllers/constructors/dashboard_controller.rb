class Constructors::DashboardController < Constructors::BaseController
  def index
    @current_qb_section = :dashboard

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

    # Decorated projects feed the new dashboard widgets (active table + alerts).
    @projects_decorated = current_user.owned_projects.includes(:project_stages).order(updated_at: :desc).map { ProjectDecorator.new(_1) }
    @active_projects = @projects_decorated.reject { |p| p.status.to_s == 'completed' }.first(5)
    @kpis = DashboardKpis.new(@projects_decorated).call
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
