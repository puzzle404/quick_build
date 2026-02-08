class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  layout "marketing"

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.role = :constructor # Asumir rol constructor por defecto

    if @user.save
      start_new_session_for(@user)
      redirect_to constructors_root_path, notice: "¡Bienvenido! Tu cuenta fue creada correctamente."
    else
      flash.now[:alert] = "Por favor corregí los errores debajo."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end

