class HomeController < ApplicationController
  # Página pública, no requiere autenticación
  allow_unauthenticated_access

  def index
    # Si el usuario está autenticado, dirigirlo a su dashboard correspondiente
    if current_user
      case current_user.role
      when 'constructor', 'admin'
        redirect_to constructors_root_path and return
      when 'buyer', 'seller'
        # Mantener acceso al home público por ahora; no redirigimos para que vean novedades
        # redirect_to products_path and return
      end
    end
  end
end
