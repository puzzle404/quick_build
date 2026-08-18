# frozen_string_literal: true

# Visor de plano: toolbar + canvas + panel de mediciones + modales (material y
# escala manual). Es el bloque que vivía en `blueprints/show.html.erb`; ahora se
# monta dentro del workspace de `blueprints#index` para que Planos sea UNA vista.
#
# El markup del `data-controller="blueprint-viewer"` se mantiene equivalente al
# original: mismos values y mismos targets (canvas, container, zoomLevel,
# scaleButton, scaleButtonText, scaleIndicator, toolButton, measurementsList,
# materialModal, materialList, manualScaleModal, manualScalePixels,
# manualScaleRatio, saveStatus). El Stimulus controller no se tocó.
class Constructors::Projects::Blueprints::ViewerComponent < ViewComponent::Base
  # Panel extra que se apila debajo de "Mediciones" en la columna derecha.
  # Hoy lo usa el workspace para meter ahí el panel de Análisis IA sin sumar
  # una cuarta columna.
  renders_one :aside

  # Alto del área de trabajo. En `show` el visor tenía la pantalla entera; acá
  # comparte pantalla con la portada del proyecto + tabs + header strip.
  VIEWPORT_HEIGHT = "height:clamp(440px, calc(100vh - 430px), 900px);"

  TOOL_BTN = "display:inline-flex;align-items:center;justify-content:center;gap:4px;height:28px;" \
             "padding:0 9px;border-radius:var(--radius);border:1px solid var(--color-line-2);" \
             "background:var(--color-bg-raised);color:var(--color-ink-2);font-size:12px;cursor:pointer;"

  DIVIDER = "width:1px;height:20px;background:var(--color-line);margin:0 2px;"

  # Modales del visor: `position:fixed` para que no los recorte el overflow del
  # workspace. Arrancan ocultos con `.hidden` (regla `[data-theme] .hidden` con
  # !important, que gana sobre el display:flex inline) y el JS los muestra
  # sacando/poniendo esa clase — igual que antes.
  MODAL_BACKDROP = "display:flex;position:fixed;inset:0;z-index:60;background:rgba(0,0,0,0.5);" \
                   "align-items:center;justify-content:center;padding:20px;"

  MODAL_PANEL = "width:100%;max-width:448px;border-radius:10px;background:var(--color-bg-raised);" \
                "border:1px solid var(--color-line);padding:22px;"

  def initialize(project:, blueprint:, construction_items: {})
    @project = project
    @blueprint = blueprint
    @construction_items = construction_items.presence || {}
  end

  attr_reader :project, :blueprint, :construction_items

  # Dibujar escala y mediciones persiste en el plano (update_scale /
  # update_measurements): es editor de obra en adelante. Zoom/pan quedan para
  # todos, que son sólo vista.
  def can_measure?
    return @can_measure if defined?(@can_measure)

    @can_measure = helpers.policy(project).manage_content?
  end

  def file_attached?
    blueprint.present? && blueprint.file.attached?
  end

  def image_url
    helpers.url_for(blueprint.file)
  end

  # Los grupos ya guardados; el JS los levanta del value `measurements`.
  def measurement_groups
    return [] unless blueprint&.measurements.is_a?(Hash)

    blueprint.measurements["groups"] || blueprint.measurements[:groups] || []
  end

  def scale_ratio_value
    blueprint&.scale_ratio || 0
  end

  def scale_label
    return "Sin escala definida" if blueprint&.scale_ratio.blank?

    "Escala: 1:#{number_with_precision(blueprint.scale_ratio, precision: 0)}"
  end

  def file_size
    return nil if blueprint.file_byte_size.blank?

    number_to_human_size(blueprint.file_byte_size)
  end
end
