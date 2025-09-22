module RolesHelper
  def constructor?
    current_user&.role == 'constructor'
  end

  def buyer?
    current_user&.role == 'buyer'
  end

  def seller?
    current_user&.role == 'seller'
  end

  def admin?
    current_user&.role == 'admin'
  end
end
