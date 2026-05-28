class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  layout -> { mobile_layout_or("marketing") }

  def new
    @user = User.new
  end

  # Mobile "Perfil / Ajustes" tab lands here. Read-only summary for now;
  # the actual edit flow lives in the upcoming user-preferences work.
  def edit
    @user = current_user
    redirect_to new_session_path and return unless @user
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

