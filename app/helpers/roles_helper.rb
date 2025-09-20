module RolesHelper
  def constructor?
    current_user&.role == 'constructor'
  end

  def buyer?
    current_user&.role == 'buyer'
  end
end
