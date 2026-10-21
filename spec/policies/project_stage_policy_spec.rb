require 'rails_helper'

RSpec.describe ProjectStagePolicy do
  include_context 'roles de obra'

  let(:record) { create(:project_stage, project: project) }

  include_examples 'permiso de obra', :show?,
                   allowed: %i[owner project_admin editor viewer platform_admin]

  include_examples 'permiso de obra', :create?,
                   allowed: %i[owner project_admin editor platform_admin]

  include_examples 'permiso de obra', :update?,
                   allowed: %i[owner project_admin editor platform_admin]

  include_examples 'permiso de obra', :destroy?,
                   allowed: %i[owner project_admin editor platform_admin]

  include_examples 'permiso de obra', :duplicate?,
                   allowed: %i[owner project_admin editor platform_admin]

  include_examples 'permiso de obra', :complete?,
                   allowed: %i[owner project_admin editor platform_admin]
end
