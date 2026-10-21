# frozen_string_literal: true

require "rails_helper"

# Feedback 29/09: "Cerrar sesión debería estar en el costado derecho y
# mostrarse cuando uno hace click en su usuario".
RSpec.describe Qb::Layout::TopbarComponent, type: :component do
  let(:user) { create(:user, :constructor, email: "miguel@obra.com") }

  it "el avatar abre un menú con Perfil y Cerrar sesión" do
    with_request_url "/constructors" do
      render_inline(described_class.new(user: user))
    end

    expect(page).to have_css("button[aria-label='Menú de cuenta'][aria-haspopup='menu']")
    expect(page).to have_link("Perfil", href: "/registration/edit", visible: :all)
    expect(page).to have_css("form[action='/session'] input[name='_method'][value='delete']", visible: :all)
    expect(page).to have_button("Cerrar sesión", visible: :all)
    expect(page).to have_text(:all, "miguel@obra.com")
  end
end
