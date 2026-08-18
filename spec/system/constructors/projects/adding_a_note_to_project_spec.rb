# frozen_string_literal: true

require "rails_helper"

# JS (Cuprite): "Agregar nota" abre el form real de notes#new dentro del
# drawer (Turbo Frame), así que hace falta un navegador para seguir el flujo.
RSpec.describe "Adding a note to a project", type: :system, js: true do
  let(:owner) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner, name: "Proyecto Test") }

  before { sign_in_user(owner) }

  it "owner can add a note and see it in the list" do
    # Regression guard for a bug fixed by infra-fix-3/4 (drawer-unification
    # plan): NotesController#create's project-scoped branch used to respond
    # with `turbo_stream.refresh` and no explicit request_id override, which
    # defaulted to `request_id: Turbo.current_request_id` — the SAME id as
    # the in-flight request. Turbo Drive treated that as "this tab already
    # knows the outcome" and skipped the refresh, so the drawer never closed
    # and the notes list never re-rendered. Fixed by passing
    # `request_id: nil` explicitly (see notes_controller.rb#create).
    #
    # The same refresh is also what surfaces the flash notice (the drawer
    # response itself has no place to render it), so both halves of that fix
    # are asserted below.
    visit constructors_project_path(project)

    click_on "Agregar nota"

    fill_in "Nota", with: "Coordinar con el arquitecto la semana próxima"
    click_button "Guardar"

    expect(page).to have_text("Coordinar con el arquitecto la semana próxima", wait: 5)
    expect(page).to have_text("Nota agregada correctamente")
  end
end
