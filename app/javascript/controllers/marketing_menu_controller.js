import { Controller } from "@hotwired/stimulus"

// Menú hamburguesa del navbar público (layout marketing). El panel se oculta
// con la utilidad `hidden` de Tailwind; acá sólo se togglea y se cierra con
// Escape o tocando el backdrop. Controller propio (y no `dropdown`) porque el
// header ya contiene un `dropdown` para el menú de usuario y los targets se
// pisarían.
export default class extends Controller {
    static targets = ["panel"]

    open() {
        this.panelTarget.classList.remove("hidden")
        document.body.style.overflow = "hidden"
    }

    close() {
        this.panelTarget.classList.add("hidden")
        document.body.style.overflow = ""
    }

    toggle() {
        if (this.panelTarget.classList.contains("hidden")) {
            this.open()
        } else {
            this.close()
        }
    }

    closeOnEsc(event) {
        if (event.key === "Escape") this.close()
    }
}
