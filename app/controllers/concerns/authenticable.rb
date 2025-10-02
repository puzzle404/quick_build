module Authenticable
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?, :current_session, :after_authentication_url, :current_user
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def authenticated?
    resume_session.present?
  end

  def current_session
    resume_session
  end

  def current_user
    Current.session&.user
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.session ||= find_session_by_cookie
  end

  def find_session_by_cookie
    session_id = cookies.signed[:session_id]
    Session.find_by(id: session_id) if session_id
  end

  def request_authentication
    store_after_authentication_url
    
    if hotwire_native_app?
      head :unauthorized and return
    end

    redirect_to new_session_path, allow_other_host: false
  end

  def store_after_authentication_url
    return if request.path == new_registration_path

    session[:return_to_after_authenticating] = request.url
  end

  def after_authentication_url(default: root_path)
    return refresh_app_path if hotwire_native_app?

    session.delete(:return_to_after_authenticating) || default
  end

  def start_new_session_for(user)
    Session.create!(
      user: user,
      user_agent: request.user_agent,
      ip_address: request.remote_ip
    ).tap do |session_record|
      Current.session = session_record
      cookies.signed.permanent[:session_id] = {
        value: session_record.id,
        httponly: true,
        same_site: :lax
      }
    end
  end

  def terminate_session
    resume_session&.destroy
    cookies.delete(:session_id)
    Current.session = nil
  end
end
