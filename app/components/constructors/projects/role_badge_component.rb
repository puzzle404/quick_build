# frozen_string_literal: true

# Pill con el rol del usuario EN ESTA OBRA (no el rol de plataforma).
#
# Se muestra al lado del nombre de la obra para que quien no ve ciertos botones
# entienda por qué. Por defecto NO se renderiza para el dueño: el owner tiene
# todo habilitado, así que el pill sería ruido.
#
#   render Constructors::Projects::RoleBadgeComponent.new(project: @project, user: current_user)
#   render Constructors::Projects::RoleBadgeComponent.new(role: :editor, variant: :mobile)
#
# Fuente única de las etiquetas es-AR de los roles: el select de invitación y
# la lista de miembros del equipo leen `LABELS` / `.options` de acá para no
# divergir con lo que muestra el pill.
class Constructors::Projects::RoleBadgeComponent < ViewComponent::Base
  LABELS = {
    owner: "Dueño",
    admin: "Administrador",
    editor: "Editor",
    viewer: "Lector"
  }.freeze

  TONES = {
    owner: :ok,
    admin: :accent,
    editor: :info,
    viewer: :muted
  }.freeze

  # Qué puede hacer cada rol, en una línea. Va en el `title` del pill y como
  # subtítulo en la lista de miembros del equipo.
  HINTS = {
    owner: "Acceso total: además de todo lo anterior, puede eliminar la obra.",
    admin: "Puede editar los datos de la obra y gestionar el equipo.",
    editor: "Puede cargar etapas, gastos, materiales, planos y fotos. No edita la obra ni el equipo.",
    viewer: "Sólo lectura: ve toda la obra pero no puede modificar nada."
  }.freeze

  # Roles asignables a una membresía (el dueño no se invita: sale de owner_id).
  ASSIGNABLE = %i[viewer editor admin].freeze

  def self.label_for(role)
    LABELS[role&.to_sym] || role.to_s.humanize.presence || "Sin rol"
  end

  def self.hint_for(role)
    HINTS[role&.to_sym]
  end

  # [['Lector', 'viewer'], …] para los selects de rol.
  def self.options
    ASSIGNABLE.map { |role| [ LABELS.fetch(role), role.to_s ] }
  end

  # `role:` explícito o resuelto desde (project, user). `show_owner:` deja
  # mostrarlo igual en contextos donde el pill es informativo (lista de equipo).
  def initialize(project: nil, user: nil, role: nil, variant: :desktop, show_owner: false)
    @role = (role || project&.role_for(user))&.to_sym
    @variant = variant.to_sym
    @show_owner = show_owner
  end

  attr_reader :role, :variant, :show_owner

  def render?
    role.present? && (show_owner || role != :owner)
  end

  def call
    if variant == :mobile
      render(Qb::Mobile::PillComponent.new(label, tone: tone, dense: true))
    else
      tag.span(title: hint) do
        render(Qb::PillComponent.new(label, tone: tone, compact: true))
      end
    end
  end

  private

  def label
    self.class.label_for(role)
  end

  def tone
    TONES.fetch(role, :muted)
  end

  def hint
    self.class.hint_for(role)
  end
end
