# frozen_string_literal: true

class Layout::NavbarComponent < ViewComponent::Base
  def initialize(current_user: nil)
    @current_user = current_user
  end
  
  def user_initials
    return "U" unless @current_user&.email
    @current_user.email[0].upcase
  end
  
  def authenticated?
    @current_user.present?
  end
end
