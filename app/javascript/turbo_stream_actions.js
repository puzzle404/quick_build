// Custom Turbo Stream action for the ONE case in the drawer unification that
// needs a real full-page Turbo.visit instead of an in-place frame patch:
// creating a brand new project from the global "+ Nuevo proyecto" trigger.
// Every other drawer close/patch in this app is handled by either a plain
// redirect_to (followed as a frame-scoped request by Turbo) or the native
// turbo_stream.refresh action — this one is reserved for "abandon the current
// page/sidebar context entirely, go to a brand new page".
Turbo.StreamActions.redirect = function () {
  Turbo.visit(this.getAttribute("target"))
}
