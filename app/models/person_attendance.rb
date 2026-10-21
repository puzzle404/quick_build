class PersonAttendance < ApplicationRecord
  # Tope de una jornada. Más de 24 horas en un mismo día no es una jornada
  # larga: es un error de tipeo, y multiplicado por la tarifa se convierte en
  # un costo de mano de obra inventado.
  MAX_HOURS = 24

  # Cuántas marcas muestra la ficha de persona. Vive acá porque el listado y
  # el recálculo del total (update de horas) tienen que usar el mismo corte:
  # si no, el total del pie deja de coincidir con las filas de arriba.
  RECENT_LIMIT = 10

  belongs_to :project_person

  scope :recent_first, -> { order(occurred_at: :desc) }

  validates :occurred_at, presence: true

  # Un solo `message` para los tres casos (no numérico, <= 0 y > 24) porque
  # los tres se corrigen igual y el texto sirve para todos. Va explícito acá:
  # es-AR.yml no tiene traducidos los mensajes de numericality y el fallback
  # a :en los devolvía en inglés ("is not a number").
  validates :hours,
            numericality: {
              greater_than: 0,
              less_than_or_equal_to: MAX_HOURS,
              message: "tienen que ser un número entre 0 y #{MAX_HOURS} (se aceptan medias horas: 7,5)"
            },
            allow_nil: true

  # Las horas se tipean a mano en la obra y en es-AR el separador decimal es
  # la coma: "7,5" tiene que valer lo mismo que "7.5". Sin normalizar,
  # ActiveRecord castea "7,5" a 7.0 y se pierde media hora en silencio.
  #
  # El string vacío borra las horas (nil) en vez de dejarlas en 0: vaciar el
  # campo es "no sé cuántas trabajó", no "trabajó cero".
  def hours=(value)
    if value.is_a?(String)
      value = value.strip.tr(",", ".")
      value = nil if value.empty?
    end

    super
  end

  def coordinates?
    latitude.present? && longitude.present?
  end

  # Costo de esta marca: tarifa de la persona × horas trabajadas. nil cuando
  # falta cualquiera de los dos — un 0 sería un dato fabricado.
  def cost_cents
    rate = project_person&.hourly_rate_cents
    return nil if rate.blank? || hours.blank?

    (hours.to_d * rate.to_i).round
  end
end
