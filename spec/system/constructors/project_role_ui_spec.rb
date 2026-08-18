# frozen_string_literal: true

require "rails_helper"

# La UI tiene que contar la misma historia que las policies: si el rol no
# alcanza, el botón no está en el HTML. Un botón visible que termina en "no
# tenés permiso" es peor que no tenerlo.
#
# Las aserciones van sobre `page.html` y no sobre el texto visible porque
# varias acciones viven dentro del kebab o de un modal, que arrancan ocultos:
# con `have_text` un item del menú daría "no visible" aunque cualquiera pueda
# abrirlo. Lo que queremos garantizar es que ni siquiera se renderice.
RSpec.describe "Acciones de obra según el rol del miembro", type: :system do
  # Acciones de escritura de la landing de la obra (Etapas).
  EDITOR_ACTIONS = [ "Registrar gasto", "Nueva etapa", "Aplicar plantilla", "Agregar nota" ].freeze
  ADMIN_ACTIONS  = [ "Editar proyecto", "Invitar", "Cambiar portada" ].freeze
  OWNER_ACTIONS  = [ "Eliminar obra" ].freeze

  let(:owner)  { create(:user, :constructor) }
  let(:viewer) { create(:user, :constructor) }
  let(:editor) { create(:user, :constructor) }
  let!(:project) { create(:project, owner: owner, name: "Torre Aurora") }

  before do
    create(:project_membership, project: project, user: viewer, role: :viewer)
    create(:project_membership, project: project, user: editor, role: :editor)
  end

  # El pill de rol es el único `<span title="<pista del rol>">` de la pantalla:
  # los chips de "Equipo asignado" y la ayuda del modal de invitación repiten
  # las etiquetas, así que buscar el texto suelto daría falsos positivos.
  def role_badge_selector(role)
    hint = Constructors::Projects::RoleBadgeComponent.hint_for(role)
    "span[title='#{hint}']"
  end

  def expect_actions(labels, visible:)
    labels.each do |label|
      if visible
        expect(page.html).to include(label), "debería ver «#{label}»"
      else
        expect(page.html).not_to include(label), "no debería ver «#{label}»"
      end
    end
  end

  it "un lector entra a la obra y no ve ninguna acción de escritura" do
    sign_in_user(viewer)
    visit constructors_project_path(project)

    expect(page).to have_text("Torre Aurora")
    expect_actions(EDITOR_ACTIONS + ADMIN_ACTIONS + OWNER_ACTIONS, visible: false)

    # Y sabe por qué: el pill dice qué rol tiene en esta obra.
    expect(page).to have_selector(role_badge_selector(:viewer), visible: :all)
  end

  it "un editor ve las acciones de carga pero no las de administración" do
    sign_in_user(editor)
    visit constructors_project_path(project)

    expect_actions(EDITOR_ACTIONS, visible: true)
    expect_actions(ADMIN_ACTIONS + OWNER_ACTIONS, visible: false)

    expect(page).to have_selector(role_badge_selector(:editor), visible: :all)
  end

  it "el dueño ve todo y no le muestra pill de rol" do
    sign_in_user(owner)
    visit constructors_project_path(project)

    expect_actions(EDITOR_ACTIONS + ADMIN_ACTIONS + OWNER_ACTIONS, visible: true)

    # El dueño tiene todo habilitado: el pill sería ruido.
    %i[viewer editor admin].each do |role|
      expect(page).to have_no_selector(role_badge_selector(role), visible: :all)
    end
  end

  it "en la pestaña Equipo el lector ve los accesos pero no puede tocarlos" do
    sign_in_user(viewer)
    visit constructors_project_people_path(project)

    expect(page).to have_text("Accesos a la obra")
    expect(page).to have_text(owner.email)
    expect(page).to have_text("Dueño de la obra")

    expect_actions([ "Invitar persona", "Invitar miembro", "Quitar" ], visible: false)
  end

  it "un admin de obra puede invitar y quitar miembros desde Equipo" do
    admin = create(:user, :constructor)
    create(:project_membership, project: project, user: admin, role: :admin)

    sign_in_user(admin)
    visit constructors_project_people_path(project)

    expect_actions([ "Invitar persona", "Invitar miembro", "Quitar" ], visible: true)
    # El dueño no se puede quitar: su acceso sale de owner_id, no de una membresía.
    expect(page).to have_text("Dueño de la obra")
  end
end
