import { Controller } from "@hotwired/stimulus"

// Muestra el/los archivo(s) elegidos en input[type=file] — el input real
// vive oculto (clase qb-file-field-input) dentro de un <label> que hace de
// botón visible; el browser no expone esa info en ningún lado por sí solo.
//
// Con el target `list` (Qb::FileFieldComponent no compacto) además lista lo
// elegido: miniatura si es imagen, nombre y peso. Y deja deshabilitados los
// botones del form marcados con data-qb-file-submit hasta que haya archivos:
// subir sin adjuntar nada no tiene sentido (feedback 21/10). Lo usa también
// el form de subida mobile, que tiene un input nativo y no usa `name`.
export default class extends Controller {
  static targets = ["input", "name", "list"]

  connect() {
    this.update()
  }

  disconnect() {
    this._revokePreviews()
  }

  update() {
    const files = Array.from(this.inputTarget.files || [])
    if (this.hasNameTarget) this.nameTarget.textContent = summary(files)
    if (this.hasListTarget) this._renderList(files)
    this._syncSubmit(files.length > 0)
  }

  _renderList(files) {
    this._revokePreviews()
    const list = this.listTarget
    list.replaceChildren()
    list.hidden = files.length === 0

    files.forEach((file) => {
      const item = document.createElement("li")
      let thumb
      if (file.type.startsWith("image/")) {
        thumb = document.createElement("img")
        thumb.src = URL.createObjectURL(file)
        thumb.alt = ""
        this._previews.push(thumb.src)
      } else {
        thumb = document.createElement("span")
        thumb.textContent = (file.name.split(".").pop() || "").slice(0, 4).toUpperCase()
      }
      thumb.className = "qb-file-field-thumb"

      const name = document.createElement("span")
      name.className = "qb-file-field-file"
      name.textContent = file.name
      name.title = file.name

      const size = document.createElement("span")
      size.className = "qb-file-field-size"
      size.textContent = humanSize(file.size)

      item.append(thumb, name, size)
      list.append(item)
    })
  }

  _syncSubmit(hasFiles) {
    const form = this.element.closest("form") || this.element.querySelector("form")
    form?.querySelectorAll("[data-qb-file-submit]").forEach((button) => { button.disabled = !hasFiles })
  }

  _revokePreviews() {
    (this._previews || []).forEach((url) => URL.revokeObjectURL(url))
    this._previews = []
  }
}

function summary(files) {
  if (files.length === 0) return "Ningún archivo seleccionado"
  if (files.length === 1) return files[0].name
  return `${files.length} archivos seleccionados`
}

function humanSize(bytes) {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1).replace(".", ",")} MB`
}
