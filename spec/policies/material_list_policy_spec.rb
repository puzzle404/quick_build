require 'rails_helper'

RSpec.describe MaterialListPolicy do
  include_context 'roles de obra'

  let(:record) { create(:material_list, project: project, author: owner) }

  include_examples 'permiso de obra', :show?,
                   allowed: %i[owner project_admin editor viewer platform_admin]

  include_examples 'permiso de obra', :create?,
                   allowed: %i[owner project_admin editor platform_admin]

  include_examples 'permiso de obra', :update?,
                   allowed: %i[owner project_admin editor platform_admin]

  include_examples 'permiso de obra', :destroy?,
                   allowed: %i[owner project_admin editor platform_admin]

  include_examples 'permiso de obra', :toggle_publication?,
                   allowed: %i[owner project_admin editor platform_admin]
end
