class Users::SessionsController < Devise::SessionsController
  def create
    user = User.find_by(email: params[:user][:email])
    if user&.valid_password?(params[:user][:password])
      sign_in(:user, user)
      redirect_to root_path and return
    end

    flash.now[:alert] = 'Invalid email or password'
    self.resource = resource_class.new(sign_in_params)
    render :new, status: :unprocessable_entity
  end

  def destroy
    sign_out(:user)
    redirect_to root_path
  end
end
