require 'rails_helper'

RSpec.describe Project, type: :model do
  it { should belong_to(:owner).class_name('User') }
  it { should validate_presence_of(:name) }
  it { should define_enum_for(:status).with_values(%i[planned in_progress completed]) }

  describe '#role_for' do
    let(:owner)   { create(:user, :constructor) }
    let(:project) { create(:project, owner: owner) }

    it 'devuelve :owner por owner_id, sin membresía de por medio' do
      expect(project.members).not_to include(owner)
      expect(project.role_for(owner)).to eq :owner
    end

    it 'devuelve el rol de la membresía' do
      %i[viewer editor admin].each do |role|
        user = create(:user, :constructor)
        create(:project_membership, project: project, user: user, role: role)

        expect(project.role_for(user)).to eq role
      end
    end

    it 'devuelve nil para alguien de afuera' do
      expect(project.role_for(create(:user, :constructor))).to be_nil
    end

    it 'devuelve nil sin usuario' do
      expect(project.role_for(nil)).to be_nil
    end

    it 'trata la membresía con role NULL (data vieja) como viewer' do
      user = create(:user, :constructor)
      membership = create(:project_membership, project: project, user: user, role: :editor)
      membership.update_column(:role, nil)

      expect(project.role_for(user)).to eq :viewer
    end

    it 'traduce los roles numéricos que dejó el enum posicional viejo' do
      user = create(:user, :constructor)
      membership = create(:project_membership, project: project, user: user, role: :viewer)
      membership.update_column(:role, '1')

      expect(project.role_for(user)).to eq :editor
    end

    it 'el owner le gana a su propia membresía' do
      create(:project_membership, project: project, user: owner, role: :viewer)

      expect(project.role_for(owner)).to eq :owner
    end
  end

  describe 'helpers de acceso' do
    let(:owner)   { create(:user, :constructor) }
    let(:project) { create(:project, owner: owner) }
    let(:viewer)  { create(:user, :constructor) }
    let(:editor)  { create(:user, :constructor) }
    let(:admin)   { create(:user, :constructor) }

    before do
      create(:project_membership, project: project, user: viewer, role: :viewer)
      create(:project_membership, project: project, user: editor, role: :editor)
      create(:project_membership, project: project, user: admin,  role: :admin)
    end

    it 'accessible_by? desde viewer para arriba' do
      expect(project.accessible_by?(viewer)).to be true
      expect(project.accessible_by?(create(:user, :constructor))).to be false
    end

    it 'editable_by? desde editor para arriba' do
      expect(project.editable_by?(viewer)).to be false
      expect(project.editable_by?(editor)).to be true
      expect(project.editable_by?(admin)).to be true
      expect(project.editable_by?(owner)).to be true
    end

    it 'manageable_by? desde admin para arriba' do
      expect(project.manageable_by?(editor)).to be false
      expect(project.manageable_by?(admin)).to be true
      expect(project.manageable_by?(owner)).to be true
    end

    it 'owned_by? sólo para el owner' do
      expect(project.owned_by?(admin)).to be false
      expect(project.owned_by?(owner)).to be true
    end
  end

  describe '.accessible_by' do
    let(:user)  { create(:user, :constructor) }
    let!(:mine) { create(:project, owner: user, name: 'Propia') }
    let!(:shared) { create(:project, name: 'Compartida') }
    let!(:ajena)  { create(:project, name: 'Ajena') }

    before { create(:project_membership, project: shared, user: user, role: :viewer) }

    it 'devuelve propias + donde soy miembro, y nada más' do
      expect(described_class.accessible_by(user)).to contain_exactly(mine, shared)
    end

    it 'no devuelve obras de otros constructores' do
      expect(described_class.accessible_by(user)).not_to include(ajena)
    end

    it 'devuelve none sin usuario' do
      expect(described_class.accessible_by(nil)).to be_empty
    end

    it 'resuelve en una sola query, sin traer ids a Ruby' do
      queries = capture_queries { described_class.accessible_by(user).to_a }

      expect(queries.size).to eq 1
      expect(queries.first).to include('IN (SELECT')
    end

    it 'no duplica filas cuando la obra propia además tiene miembros' do
      create(:project_membership, project: mine, user: create(:user, :constructor), role: :editor)

      expect(described_class.accessible_by(user).count).to eq 2
    end
  end

  describe 'memoización del rol' do
    let(:owner)   { create(:user, :constructor) }
    let(:project) { create(:project, owner: owner) }
    let(:member)  { create(:user, :constructor) }

    before { create(:project_membership, project: project, user: member, role: :editor) }

    it 'no dispara una query por fila: cachea por (obra, usuario)' do
      # 3 gastos de la misma obra, cada uno con su propia instancia de Project
      # (como en una vista con 50 filas).
      expenses = create_list(:expense, 3, project: project, author: owner).map(&:reload)

      queries = capture_queries do
        expenses.each { |e| e.project.role_for(member) }
      end

      expect(queries.grep(/project_memberships/).size).to eq 1
    end

    it 'warm_role_cache! resuelve N obras en una query y después no consulta más' do
      others = create_list(:project, 3, owner: create(:user, :constructor))
      others.each { |p| create(:project_membership, project: p, user: member, role: :editor) }
      all = [ project ] + others

      expect(count_queries { described_class.warm_role_cache!(member, all) }).to eq 1
      expect(count_queries { all.each { |p| p.role_for(member) } }).to eq 0
      expect(all.map { |p| p.role_for(member) }).to all(eq(:editor))
    end

    it 'warm_role_cache! marca al owner como owner y al ajeno como sin acceso' do
      ajena = create(:project)
      described_class.warm_role_cache!(owner, [ project, ajena ])

      expect(count_queries { project.role_for(owner) }).to eq 0
      expect(project.role_for(owner)).to eq :owner
      expect(ajena.role_for(owner)).to be_nil
    end
  end
end
