import { Controller } from "@hotwired/stimulus"

// Muestra el/los archivo(s) elegidos en input[type=file] — el input real
// vive oculto (clase qb-file-field-input) dentro de un <label> que hace de
// botón visible; el browser no expone esa info en ningún lado por sí solo.
export default class extends Controller {
  static targets = ["input", "name"]

  connect() {
    this.update()
  }

  update() {
    const files = this.inputTarget.files
    if (!files || files.length === 0) {
      this.nameTarget.textContent = "Ningún archivo seleccionado"
    } else if (files.length === 1) {
      this.nameTarget.textContent = files[0].name
    } else {
      this.nameTarget.textContent = `${files.length} archivos seleccionados`
    }
  }
}
