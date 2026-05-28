class User < ApplicationRecord
  has_secure_password

  enum :role, [ :buyer, :constructor, :admin, :seller ]

  belongs_to :company, optional: true
  has_many :orders, dependent: :destroy
  has_many :project_memberships, dependent: :destroy
  has_many :projects, through: :project_memberships
  has_many :owned_projects, class_name: 'Project', foreign_key: 'owner_id', dependent: :destroy
  has_many :material_lists, foreign_key: :author_id, dependent: :destroy
  has_many :sessions, dependent: :destroy

  validates :company, presence: true, if: :seller?

  # ─── UI preferences (Tweaks panel — web + mobile) ───────────────
  # Stored in a single jsonb column. Whitelisted keys + per-key
  # validations live here so the rest of the app reads `user.theme`,
  # `user.accent`, `user.density` and never has to think about the
  # underlying shape. Keep this list in sync with the Tweaks UI.
  PREFERENCE_KEYS = {
    theme:   { default: 'graphite', allowed: %w[graphite night] },
    accent:  { default: 'cobalt',   allowed: %w[cobalt kiln moss safety ink] },
    density: { default: 'cozy',     allowed: %w[compact cozy relaxed] }
  }.freeze

  PREFERENCE_KEYS.each_key do |key|
    define_method(key) do
      preferences[key.to_s].presence || PREFERENCE_KEYS[key][:default]
    end

    define_method("#{key}=") do |value|
      value = value.to_s
      allowed = PREFERENCE_KEYS[key][:allowed]
      self.preferences = preferences.merge(key.to_s => value) if allowed.include?(value)
    end
  end

  # Hash → assign multiple at once (used by the preferences controller).
  def update_preferences!(params)
    params.to_h.each do |k, v|
      next unless PREFERENCE_KEYS.key?(k.to_sym)
      public_send("#{k}=", v)
    end
    save!
  end
end
