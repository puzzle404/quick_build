class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[edit update]

  def new
  end

  def create
    if (user = User.find_by(email: params[:email]))
      PasswordsMailer.reset(user).deliver_later
    end

    # Respuesta neutra: no revelamos si el email existe o no.
    redirect_to new_session_path,
                notice: "Si tu email está registrado, te enviamos un enlace para restablecer la contraseña."
  end

  def edit
  end

  def update
    if @user.update(password_params)
      redirect_to new_session_path, notice: "Tu contraseña fue actualizada. Iniciá sesión con la nueva."
    else
      flash.now[:alert] = "Las contraseñas no coinciden o están vacías. Probá de nuevo."
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_password_reset_token!(params[:token])
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_password_path, alert: "El enlace de recuperación no es válido o ya venció. Pedí uno nuevo."
  end

  def password_params
    params.permit(:password, :password_confirmation)
  end
end
