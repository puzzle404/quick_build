class DashboardsController < ApplicationController
  def show
    redirect_to dashboard_path_for(current_user)
  end

  private

  def dashboard_path_for(user)
    return new_user_session_path unless user

    case user.role
    when 'constructor'
      constructors_root_path
    when 'buyer', 'seller'
      products_path
    when 'admin'
      constructors_root_path
    else
      new_user_session_path
    end
  end
end
