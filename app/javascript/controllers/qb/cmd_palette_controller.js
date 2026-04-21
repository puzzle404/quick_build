import { Controller } from "@hotwired/stimulus"

// Server-driven command palette.
//
// Behavior:
//   - "qb:open" event (or open() action) shows the dialog and focuses input.
//   - User types → debounced 200ms → fetch /constructors/search.json?q=…
//   - Response renders into `results` target as section groups (Proyectos /
//     Personas / Etapas / Materiales / Documentos / Acciones).
//   - ↑/↓ navigate between visible items, Enter activates, ESC closes.
//   - On open with empty query, fetches once to surface shortcuts + recents.
//
// The endpoint and group icons are configurable via data-values.
const ICONS = {
  projects: '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M3 7h6l2 2h10v11H3z"/></svg>',
  people:   '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="8" r="3"/><path d="M3 20c0-3.5 2.7-6 6-6s6 2.5 6 6"/><circle cx="17" cy="9" r="2.5"/><path d="M15 20c0-2.5 1.5-4.5 4-4.5"/></svg>',
  stages:   '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18M3 12h18M3 18h12"/></svg>',
  materials:'<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3l9 5-9 5-9-5 9-5z"/><path d="M3 13l9 5 9-5"/><path d="M3 18l9 5 9-5"/></svg>',
  docs:     '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M6 3h9l4 4v14H6z"/><path d="M14 3v5h5"/></svg>',
  plus:     '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M5 12h14"/></svg>',
  dashboard:'<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="9"/><rect x="14" y="3" width="7" height="5"/><rect x="14" y="12" width="7" height="9"/><rect x="3" y="16" width="7" height="5"/></svg>'
}

const GROUP_LABELS = {
  projects:       'Proyectos',
  people:         'Personas',
  stages:         'Etapas',
  material_lists: 'Listas de materiales',
  documents:      'Documentos',
  actions:        'Acciones'
}

export default class extends Controller {
  static targets = ["dialog", "input", "results", "footer"]
  static values = {
    endpoint: { type: String, default: "/constructors/search.json" },
    debounce: { type: Number, default: 200 }
  }

  connect() {
    this.activeIndex = 0
    this._items = []
    this._debounceTimer = null
    this.element.addEventListener("qb:open", () => this.open())
  }

  open() {
    if (!this.hasDialogTarget) return
    this.dialogTarget.classList.remove("hidden")
    this.dialogTarget.style.display = "flex"
    document.body.style.overflow = "hidden"
    requestAnimationFrame(() => this.inputTarget?.focus())
    this.activeIndex = 0
    this._fetchAndRender("")
  }

  close() {
    if (!this.hasDialogTarget) return
    this.dialogTarget.classList.add("hidden")
    this.dialogTarget.style.display = "none"
    document.body.style.overflow = ""
    if (this.hasInputTarget) this.inputTarget.value = ""
  }

  // ── Input handling ──────────────────────────────────────────────
  filter() {
    if (!this.hasInputTarget) return
    clearTimeout(this._debounceTimer)
    const q = this.inputTarget.value
    this._debounceTimer = setTimeout(() => this._fetchAndRender(q), this.debounceValue)
  }

  keydown(event) {
    switch (event.key) {
      case "Escape":
        event.preventDefault()
        this.close()
        break
      case "ArrowDown":
        event.preventDefault()
        this.activeIndex = Math.min(this.activeIndex + 1, this._items.length - 1)
        this._highlight()
        break
      case "ArrowUp":
        event.preventDefault()
        this.activeIndex = Math.max(this.activeIndex - 1, 0)
        this._highlight()
        break
      case "Enter":
        event.preventDefault()
        const target = this._items[this.activeIndex]
        if (target) window.location.href = target.url
        break
    }
  }

  backdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  // ── Internals ───────────────────────────────────────────────────
  async _fetchAndRender(q) {
    if (!this.hasResultsTarget) return
    try {
      const url = `${this.endpointValue}?q=${encodeURIComponent(q)}`
      const res = await fetch(url, { headers: { "Accept": "application/json" } })
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      const data = await res.json()
      this._render(data)
    } catch (err) {
      this.resultsTarget.innerHTML = `<div style="padding:24px;text-align:center;color:var(--color-bad);font-size:12px;">Error al buscar (${err.message}).</div>`
      this._items = []
    }
  }

  _render(data) {
    const groupOrder = ["projects", "people", "stages", "material_lists", "documents", "actions"]
    const flat = []
    let html = ""

    for (const key of groupOrder) {
      const items = data[key] || []
      if (items.length === 0) continue
      html += `<div style="font-size:10px;font-family:var(--font-mono);color:var(--color-ink-4);text-transform:uppercase;letter-spacing:0.7px;font-weight:500;padding:10px 12px 4px;">${GROUP_LABELS[key] || key}</div>`
      for (const item of items) {
        const idx = flat.length
        flat.push(item)
        const icon = ICONS[item.icon] || ICONS.projects
        html += `
          <a href="${item.url}" data-qb-cmd-idx="${idx}"
             style="width:100%;display:flex;align-items:center;gap:10px;padding:0 12px;height:34px;background:transparent;border:none;border-radius:5px;cursor:pointer;text-align:left;text-decoration:none;color:var(--color-ink);">
            <span style="color:var(--color-ink-4);">${icon}</span>
            <span style="flex:1;font-size:13px;color:var(--color-ink);">${this._escape(item.label)}</span>
            <span style="font-size:11px;color:var(--color-ink-4);">${this._escape(item.hint || '')}</span>
          </a>`
      }
    }

    if (flat.length === 0) {
      html = `<div style="padding:32px;text-align:center;color:var(--color-ink-4);font-size:12px;">Sin resultados. Probá con otra palabra clave.</div>`
    }

    this.resultsTarget.innerHTML = html
    this._items = flat
    this.activeIndex = Math.min(this.activeIndex, Math.max(this._items.length - 1, 0))
    this._highlight()
  }

  _highlight() {
    this.resultsTarget.querySelectorAll('[data-qb-cmd-idx]').forEach((el) => {
      const idx = Number(el.dataset.qbCmdIdx)
      const active = idx === this.activeIndex
      el.style.background = active ? 'var(--color-bg-sunken)' : 'transparent'
    })
  }

  _escape(str) {
    return String(str).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]))
  }
}
