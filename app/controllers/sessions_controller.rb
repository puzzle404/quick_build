class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create destroy]

  def new
  end

  def create
    if (user = authenticate_user)
      start_new_session_for(user)
      redirect_to after_authentication_url(default: root_path)
    else
      flash.now[:alert] = "Verificá tu email y contraseña."
      render :new, status: :unauthorized
    end
  end

  def destroy
    terminate_session
    redirect_to  new_session_path
  end

  def protected
  end

  private

  def authenticate_user
    raise
    credentials = session_params
    return unless credentials[:email].present? && credentials[:password].present?

    User.authenticate_by(email: credentials[:email], password: credentials[:password])
  end

  def session_params
    params.require(:session).permit(:email, :password)
  end
end
