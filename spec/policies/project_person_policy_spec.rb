require 'rails_helper'

RSpec.describe ProjectPersonPolicy do
  include_context 'roles de obra'

  let(:record) { create(:project_person, project: project) }

  include_examples 'permiso de obra', :index?,
                   allowed: %i[owner project_admin editor viewer platform_admin]

  include_examples 'permiso de obra', :show?,
                   allowed: %i[owner project_admin editor viewer platform_admin]

  # Alta/baja de personas es gestionar el equipo: el editor no llega.
  include_examples 'permiso de obra', :create?,
                   allowed: %i[owner project_admin platform_admin]

  include_examples 'permiso de obra', :update?,
                   allowed: %i[owner project_admin platform_admin]

  include_examples 'permiso de obra', :destroy?,
                   allowed: %i[owner project_admin platform_admin]
end
