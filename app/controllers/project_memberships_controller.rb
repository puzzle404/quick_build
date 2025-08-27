class ProjectMembershipsController < ApplicationController
  before_action :set_project

  def create
    @membership = @project.project_memberships.new(project_membership_params)
    authorize @membership
    if @membership.save
      redirect_to @project, notice: 'Member added.'
    else
      redirect_to @project, alert: 'Unable to add member.'
    end
  end

  def destroy
    @membership = @project.project_memberships.find(params[:id])
    authorize @membership
    @membership.destroy
    redirect_to @project, notice: 'Member removed.'
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def project_membership_params
    params.require(:project_membership).permit(:user_id, :role)
  end
end
