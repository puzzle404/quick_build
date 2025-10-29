class Constructors::DashboardController < Constructors::BaseController
  def index
    @dashboard = Constructors::DashboardService.perform(current_user)
  end
end

