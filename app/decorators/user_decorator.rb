class UserDecorator < BaseDecorator
  delegate_all
  
  def display_name
    "#{first_name} #{last_name}"
  end
end