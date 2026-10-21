require 'rails_helper'

RSpec.describe PersonAttendancePolicy do
  include_context 'roles de obra'

  let(:person) { create(:project_person, project: project) }
  let(:record) { create(:person_attendance, project_person: person) }

  include_examples 'permiso de obra', :show?,
                   allowed: %i[owner project_admin editor viewer platform_admin]

  # Marcar el presente pasó a ser de editor: antes lo podía hacer cualquier
  # miembro, incluido un viewer.
  include_examples 'permiso de obra', :create?,
                   allowed: %i[owner project_admin editor platform_admin]

  # Cargar las horas sobre una marca existente es la misma carga de datos de
  # obra que marcarla: editor. Un viewer ve las horas pero no las escribe.
  include_examples 'permiso de obra', :update?,
                   allowed: %i[owner project_admin editor platform_admin]

  include_examples 'permiso de obra', :destroy?,
                   allowed: %i[owner project_admin editor platform_admin]
end
