# frozen_string_literal: true

# Bitácora del rail del proyecto: una sola línea de tiempo con notas y
# actividad (más reciente primero), filtrable Todo / Notas / Actividad
# (qb--log-filter) y con nota rápida al tope — el form completo (con título)
# sigue en el drawer, vía "Agregar nota".
class Constructors::Projects::Overview::LogbookComponent < ViewComponent::Base
  # Entradas visibles de entrada; el resto se despliega con "Ver todo" (sin
  # scroll interno: el rail crece y fluye con la página).
  DEFAULT_VISIBLE = 3

  Entry = Struct.new(:kind, :title, :body, :meta, :at, :note, keyword_init: true)

  # `clamp: false` muestra cada nota completa (tab Bitácora); en espacios
  # chicos se resume a 3 líneas.
  def initialize(project:, notes:, activity_entries:, visible: DEFAULT_VISIBLE, clamp: true)
    @visible = visible
    @clamp = clamp
    @project = project
    @notes = notes
    @activity_entries = activity_entries || []
  end

  attr_reader :project, :visible

  def clamp?
    @clamp
  end

  def entries
    @entries ||= (note_entries + activity_items).sort_by { |e| e.at || Time.at(0) }.reverse
  end

  def can_add_note?
    helpers.policy(project.notes.build).create?
  end

  def can_destroy?(note)
    helpers.policy(note).destroy?
  end

  def filters
    [ [ "all", "Todo" ], [ "notes", "Notas" ], [ "activity", "Actividad" ] ]
  end

  def notes_count
    @notes.size
  end

  private

  def note_entries
    @notes.map do |note|
      # Sin título no se inventa "Nota": el cuerpo pasa a ser el texto principal.
      Entry.new(kind: "note", title: note.title.presence, body: note.body,
                meta: "#{author_label(note.author)} · hace #{time_ago_in_words(note.created_at)}", at: note.created_at, note: note)
    end
  end

  def author_label(user)
    user.try(:name).presence || user.email.to_s.split("@").first
  end

  def activity_items
    @activity_entries.map do |a|
      at = a[:timestamp]
      Entry.new(kind: "activity", title: a[:title] || a[:label] || "Actividad", body: a[:description],
                meta: at ? "hace #{time_ago_in_words(at)}" : nil, at: at)
    end
  end
end
