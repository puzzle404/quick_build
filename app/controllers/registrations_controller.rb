class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    @user = User.new
    @companies = Company.all
  end

  def create
    @user = User.new(user_params)
    @companies = Company.all

    if @user.save
      start_new_session_for(@user)
      redirect_to after_authentication_url(default: root_path), notice: "Bienvenido! Tu cuenta fue creada correctamente."
    else
      flash.now[:alert] = "Por favor corregí los errores debajo."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role, :company_id)
  end
end
