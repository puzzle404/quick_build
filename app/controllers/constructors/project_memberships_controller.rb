class  Constructors::ProjectMembershipsController < ApplicationController
  before_action :set_project

  def create
    @membership = @project.project_memberships.new(project_membership_params)
    authorize @membership
    
    if @membership.save
      redirect_to constructors_project_path(@project), notice: 'Member added.'
    else
      redirect_to constructors_project_path(@project), alert: 'Unable to add member.'
    end
  end

  def destroy
    @membership = @project.project_memberships.find(params[:id])
    authorize @membership
    @membership.destroy
    redirect_to constructors_project_path(@project), notice: 'Member removed.'
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def project_membership_params
    params.require(:project_membership).permit(:user_id, :role)
  end
end
