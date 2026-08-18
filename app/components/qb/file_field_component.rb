# frozen_string_literal: true

# Primitivo de subida de archivos: reemplaza el input[type=file] nativo (feo
# en todos los browsers — Chrome no deja restylear el color del botón nativo
# ni siquiera con ::file-selector-button + appearance:none, es una limitación
# del engine, no de la hoja de estilos) por un <label> con look de botón que
# envuelve un input visualmente oculto (accesible, funciona sin JS: el click
# en el label abre el picker por comportamiento nativo del HTML) + un texto
# que muestra el/los archivo(s) elegidos, actualizado por el controller
# Stimulus qb--file-field en el evento "change".
class Qb::FileFieldComponent < ViewComponent::Base
  def initialize(form:, method:, trigger_label: nil, multiple: false, accept: nil,
                 direct_upload: false, required: false, compact: false)
    @form = form
    @method = method
    @multiple = multiple
    @accept = accept
    @direct_upload = direct_upload
    @required = required
    @compact = compact
    @trigger_label = trigger_label || (multiple ? "Elegir archivos" : "Elegir archivo")
  end

  attr_reader :form, :method, :multiple, :accept, :direct_upload, :required, :compact, :trigger_label

  def wrapper_class
    compact ? "qb-file-field qb-file-field--compact" : "qb-file-field"
  end
end
