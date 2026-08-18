# frozen_string_literal: true

# Contexto compartido por las policy specs: una obra y un usuario por cada rol
# de la matriz de permisos. Reusable desde request specs.
RSpec.shared_context "roles de obra" do
  let(:owner)          { create(:user, :constructor) }
  let(:project)        { create(:project, owner: owner) }
  let(:project_admin)  { project_member_with(:admin) }
  let(:editor)         { project_member_with(:editor) }
  let(:viewer)         { project_member_with(:viewer) }
  let(:outsider)       { create(:user, :constructor) }
  let(:platform_admin) { create(:user, :admin) }
  let(:anon)           { nil }

  def project_member_with(role)
    create(:user, :constructor).tap do |user|
      create(:project_membership, project: project, user: user, role: role)
    end
  end
end

# Chequea una acción de policy contra todos los roles de una vez. El spec
# define `record` y `allowed` lista los roles que SÍ pueden:
#
#   include_examples "permiso de obra", :create?, allowed: %i[owner project_admin editor platform_admin]
RSpec.shared_examples "permiso de obra" do |action, allowed:|
  %i[owner project_admin editor viewer outsider platform_admin anon].each do |role|
    expected = allowed.include?(role)

    it "#{expected ? 'permite' : 'deniega'} #{action} a #{role}" do
      policy = described_class.new(public_send(role), record)
      expect(policy.public_send(action)).to eq(expected)
    end
  end
end
