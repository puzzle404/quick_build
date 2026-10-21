# frozen_string_literal: true

# Mensajes flash como toasts en la esquina inferior derecha: entran
# deslizándose de izquierda a derecha, se van solos (qb--toast) y se pueden
# cerrar a mano. Reemplaza las bandas fijas que empujaban el contenido de la
# página y pasaban desapercibidas.
#
# El contenedor `#qb_toasts` existe siempre (aunque no haya flash) para que un
# turbo_stream pueda sumar toasts sin navegar:
#   turbo_stream.append("qb_toasts", Qb::ToastComponent.new(message: "…"))
class Qb::ToastStackComponent < ViewComponent::Base
  def initialize(notice: nil, alert: nil)
    @notice = notice
    @alert = alert
  end

  def toasts
    [ ([ @notice, :ok ] if @notice.present?), ([ @alert, :bad ] if @alert.present?) ].compact
  end
end
