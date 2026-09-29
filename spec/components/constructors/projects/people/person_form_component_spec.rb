require "rails_helper"

RSpec.describe Constructors::Projects::People::PersonFormComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:project) { create(:project) }
  let(:person) { build(:project_person, project: project) }

  it "renders form fields" do
    render_inline described_class.new(project: project, person: person)
    expect(page).to have_field("Nombre y apellido")
    expect(page).to have_field("Rol / oficio")
    expect(page).to have_button("Crear persona")
  end
end

