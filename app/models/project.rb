class Project < ApplicationRecord
  include PgSearch::Model
  enum :status, [ :planned, :in_progress, :completed ]

  # Etiquetas es-AR de los estados. Fuente única: el decorator y los selects
  # de los forms (desktop y mobile) las leen de acá para no divergir.
  STATUS_LABELS = {
    "planned" => "Planificado",
    "in_progress" => "En progreso",
    "completed" => "Finalizado"
  }.freeze

  def self.status_options
    statuses.keys.map { |s| [ STATUS_LABELS.fetch(s, s.humanize), s ] }
  end

  belongs_to :owner, class_name: "User"
  has_many :project_memberships, dependent: :destroy
  has_many :members, through: :project_memberships, source: :user
  has_many :project_stages, dependent: :destroy
  has_many :material_lists, dependent: :destroy
  has_many :project_people, dependent: :destroy
  has_many :images, as: :imageable, dependent: :destroy
  has_many :documents, as: :documentable, dependent: :destroy
  has_many :blueprints, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :notes, as: :noteable, dependent: :destroy

  attr_accessor :document_files

  validates :name, presence: true

  pg_search_scope :search_text,
                  against: [ :name, :location ],
                  using: { tsearch: { prefix: true } }

  # ─── Roles y acceso por obra ─────────────────────────────────────────
  #
  # Jerarquía: owner > admin > editor > viewer.
  #   viewer → ve toda la obra, no toca nada.
  #   editor → viewer + etapas, gastos, materiales, planos/documentos/fotos,
  #            asistencia y notas.
  #   admin  → editor + datos de la obra + equipo (miembros y personas).
  #   owner  → admin + borrar la obra. Nunca pierde acceso.
  #
  # El owner NO tiene ProjectMembership propia: sale de projects.owner_id.
  # El admin de plataforma (User#admin?) no se resuelve acá a propósito —
  # eso es una decisión de autorización y vive en las policies.
  ROLE_RANK = { viewer: 1, editor: 2, admin: 3, owner: 4 }.freeze

  # :owner / :admin / :editor / :viewer, o nil si no tiene acceso.
  #
  # Memoizado por (project_id, user_id) sobre la instancia de User: dentro de
  # un request `current_user` es siempre el mismo objeto (Current.session
  # memoiza la asociación), así que 50 filas que preguntan por la misma obra
  # hacen 1 query. Para listados de N obras distintas usá
  # `Project.warm_role_cache!(user, projects)`.
  def role_for(user)
    return nil if user.nil?
    return compute_role_for(user) unless persisted?

    cache = user.project_role_cache
    cache.fetch(id) { cache[id] = compute_role_for(user) }
  end

  # ¿El rol del usuario en esta obra llega al nivel pedido?
  def role_at_least?(user, level)
    role = role_for(user)
    return false if role.nil?

    ROLE_RANK.fetch(role, 0) >= ROLE_RANK.fetch(level)
  end

  def accessible_by?(user)
    role_for(user).present?
  end

  def editable_by?(user)
    role_at_least?(user, :editor)
  end

  def manageable_by?(user)
    role_at_least?(user, :admin)
  end

  def owned_by?(user)
    role_for(user) == :owner
  end

  # Obras propias (owner_id) O donde el usuario es miembro, en UNA query:
  # la membresía entra como subquery SQL, no como ids traídos a Ruby.
  # A propósito NO contempla al admin de plataforma; para eso está
  # ProjectPolicy::Scope, que es donde vive esa excepción.
  # Acepta un User, un decorator o directamente un id.
  scope :accessible_by, ->(user) {
    user_id = user.respond_to?(:id) ? user.id : user

    if user_id.blank?
      none
    else
      where(owner_id: user_id)
        .or(where(id: ProjectMembership.where(user_id: user_id).select(:project_id)))
    end
  }

  # Precalienta el cache de roles de varias obras de una (1 query), para
  # listados donde cada fila es una obra distinta:
  #
  #   Project.warm_role_cache!(current_user, @projects)
  #   @projects.each { |p| p.editable_by?(current_user) } # 0 queries extra
  def self.warm_role_cache!(user, projects)
    return if user.nil?

    cache = user.project_role_cache
    # Acepta obras, decorators o ids.
    ids = Array(projects).map { |p| p.respond_to?(:id) ? p.id : p }.compact.uniq
    ids -= cache.keys
    return if ids.empty?

    # El filtro por user_id va en el ON, no en el WHERE: en el WHERE, una obra
    # con membresías de OTROS usuarios se caería del resultado y un owner sin
    # membresía propia quedaría sin rol.
    join = sanitize_sql_array([
      "LEFT OUTER JOIN project_memberships ON project_memberships.project_id = projects.id " \
      "AND project_memberships.user_id = ?", user.id
    ])

    where(id: ids)
      .joins(join)
      .pluck(:id, :owner_id, Arel.sql("project_memberships.id"), Arel.sql("project_memberships.role"))
      .each do |project_id, owner_id, membership_id, raw_role|
        # membership_id distingue "no hay membresía" de "hay membresía con
        # role NULL" (data vieja), que se resuelve como viewer.
        cache[project_id] = if owner_id == user.id
          :owner
        elsif membership_id
          ProjectMembership.normalize_role(raw_role) || ProjectMembership::DEFAULT_ROLE
        end
      end

    # Ids que no existen o a los que el usuario no llega: cachear el nil
    # también, así no se repregunta por cada fila.
    ids.each { |id| cache[id] = nil unless cache.key?(id) }
  end

  def progress_percent
    Projects::ProgressCalculator.new(self).percent
  end

  # Helper para saber si el proyecto tiene ubicación
  def located?
    latitude.present? && longitude.present?
  end

  def spent_to_date_cents
    Projects::SpendSummary.new(self).total_cents
  end

  private

  def compute_role_for(user)
    return :owner if owner_id.present? && owner_id == user.id

    membership = find_membership_for(user)
    return nil if membership.nil?

    membership.effective_role
  end

  # Si la asociación ya está cargada (includes(:project_memberships)) usamos
  # lo que hay en memoria; si no, una query puntual por (project, user).
  def find_membership_for(user)
    if project_memberships.loaded?
      project_memberships.detect { |m| m.user_id == user.id }
    else
      project_memberships.find_by(user_id: user.id)
    end
  end
end
