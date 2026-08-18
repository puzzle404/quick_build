import { Controller } from "@hotwired/stimulus"

// Sets the `qb_mobile_client` cookie so Rails can pick the `:mobile` variant
// for the *next* request. Triggers in three situations:
//
//   1. The page is rendered in standalone PWA mode (Add to Home Screen).
//      `display-mode: standalone` is the cross-browser signal; Safari iOS
//      also exposes `navigator.standalone === true` as a legacy fallback.
//   2. The viewport is narrower than the breakpoint (default 768px) — covers
//      phone browsers regardless of UA, and DevTools responsive mode.
//   3. The UA already triggered server-side detection — in that case we just
//      keep the cookie fresh so it survives across sessions.
//
// When the user resizes from mobile to desktop (or vice versa), the cookie
// updates and the next navigation re-renders with the right variant. We
// don't force a reload — letting the next navigation pick up the change is
// less jarring than yanking the page underfoot.
//
// To disable (e.g. for tests), set `data-qb--mobile-detect-disabled-value`.
export default class extends Controller {
  static values = {
    breakpoint: { type: Number, default: 768 },
    cookieName: { type: String, default: "qb_mobile_client" },
    disabled:   { type: Boolean, default: false }
  }

  connect() {
    if (this.disabledValue) return
    this._update()
    this._listen()
  }

  disconnect() {
    this._mql?.removeEventListener?.("change", this._boundUpdate)
    window.removeEventListener("resize", this._boundUpdate)
  }

  _listen() {
    this._boundUpdate = this._update.bind(this)
    // matchMedia is more efficient than 'resize' for breakpoint changes,
    // but we listen to both so DevTools responsive mode (which can change
    // viewport without firing media-query events on some Chrome versions)
    // still works.
    this._mql = window.matchMedia(`(max-width: ${this.breakpointValue}px)`)
    this._mql.addEventListener?.("change", this._boundUpdate)
    window.addEventListener("resize", this._boundUpdate, { passive: true })
  }

  _update() {
    const isStandalone = window.matchMedia("(display-mode: standalone)").matches ||
                         window.navigator.standalone === true
    const isNarrow = window.innerWidth <= this.breakpointValue
    const wantMobile = isStandalone || isNarrow
    this._writeCookie(wantMobile ? "1" : "0")
  }

  _writeCookie(value) {
    // 30-day TTL so the choice survives sessions but doesn't pile up.
    const maxAge = 60 * 60 * 24 * 30
    const secure = window.location.protocol === "https:" ? "; Secure" : ""
    document.cookie = `${this.cookieNameValue}=${value}; path=/; max-age=${maxAge}; SameSite=Lax${secure}`
  }
}
