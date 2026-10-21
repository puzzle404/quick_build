class ProjectMembership < ApplicationRecord
  # OJO: `role` es una columna string. Antes estaba declarado como enum
  # posicional (`enum :role, [:viewer, :editor, :admin]`), que mapea a 0/1/2:
  # Rails guardaba "1" en la columna y al leerla devolvía nil, así que ningún
  # rol sobrevivía al round-trip. Ahora el enum guarda el label tal cual.
  # LEGACY_ROLES traduce los valores numéricos que quedaron de la versión vieja.
  ROLES = { viewer: "viewer", editor: "editor", admin: "admin" }.freeze
  LEGACY_ROLES = { "0" => :viewer, "1" => :editor, "2" => :admin }.freeze

  # Membresías viejas (anteriores a `validates :role`) tienen role NULL.
  # Se las trata como el rol más bajo: ver, no tocar.
  DEFAULT_ROLE = :viewer

  enum :role, ROLES

  belongs_to :user
  belongs_to :project

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :project_id }

  # Traduce un valor crudo de la columna a símbolo (:viewer/:editor/:admin).
  # Devuelve nil si no reconoce el valor (NULL, basura) — el llamador decide
  # con qué default resolverlo.
  def self.normalize_role(raw)
    return nil if raw.nil?

    value = raw.to_s
    return value.to_sym if ROLES.key?(value.to_sym)

    LEGACY_ROLES[value]
  end

  # Rol efectivo de esta membresía, ya resuelto contra los valores legacy y
  # el default. Siempre devuelve un símbolo válido.
  def effective_role
    self.class.normalize_role(role || role_before_type_cast) || DEFAULT_ROLE
  end
end
