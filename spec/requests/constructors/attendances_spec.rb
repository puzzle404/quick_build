require 'rails_helper'

# `person_attendances.hours` existía en la tabla desde siempre pero nadie la
# escribía (0 de 6 registros la tenían): attendance_params sólo permitía
# lat/lng/notes/source y "Dar presente" era un link sin formulario. El KPI
# "Costo MO" (tarifa × horas) era guion permanente.
RSpec.describe 'Constructors::People::Attendances', type: :request do
  include_context 'roles de obra'

  let(:person) { create(:project_person, project: project, full_name: 'Carla Ruiz') }

  before { sign_in(owner) }

  describe 'POST create' do
    it 'registra el presente' do
      post constructors_project_person_attendances_path(project, person),
           params: { person_attendance: { latitude: -34.6, longitude: -58.38, source: 'manual' } }
      follow_redirect!
      expect(response.body).to include('Presente registrado').or include('Asistencias')
    end

    # Dar presente es de un click, parado en la obra. Poner 8 horas por
    # defecto sería fabricar el dato que después multiplica a la tarifa.
    it 'no inventa horas: la marca nace sin jornada cargada' do
      post constructors_project_person_attendances_path(project, person)

      expect(person.person_attendances.last.hours).to be_nil
    end
  end

  describe 'PATCH update (carga de horas)' do
    let(:attendance) { create(:person_attendance, project_person: person, occurred_at: 1.day.ago) }

    it 'guarda las horas tipeadas con coma decimal' do
      patch constructors_project_person_attendance_path(project, person, attendance),
            params: { person_attendance: { hours: '7,5' } }

      expect(attendance.reload.hours).to eq(BigDecimal('7.5'))
    end

    it 'responde el turbo_stream con la fila y el total recalculados' do
      patch constructors_project_person_attendance_path(project, person, attendance),
            params: { person_attendance: { hours: '8' } },
            headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include("attendance_row_#{attendance.id}")
      expect(response.body).to include('attendance_hours_total')
    end

    it 'sin turbo vuelve a la ficha (form-per-row funciona sin JS)' do
      patch constructors_project_person_attendance_path(project, person, attendance),
            params: { person_attendance: { hours: '8' } }

      expect(response).to redirect_to(constructors_project_person_path(project, person))
      expect(attendance.reload.hours).to eq(8)
    end

    it 'vaciar el campo BORRA las horas (el string vacío tiene que limpiar)' do
      attendance.update!(hours: 8)

      patch constructors_project_person_attendance_path(project, person, attendance),
            params: { person_attendance: { hours: '' } }

      expect(attendance.reload.hours).to be_nil
    end

    it 'sin la clave hours no toca nada' do
      attendance.update!(hours: 8)

      patch constructors_project_person_attendance_path(project, person, attendance),
            params: { person_attendance: { notes: 'otra cosa' } }

      expect(attendance.reload.hours).to eq(8)
    end

    it 'rechaza un valor fuera de rango sin pisar el dato guardado' do
      attendance.update!(hours: 8)

      patch constructors_project_person_attendance_path(project, person, attendance),
            params: { person_attendance: { hours: '25' } },
            headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('entre 0 y 24')
      expect(attendance.reload.hours).to eq(8)
    end

    it 'un editor puede cargar horas' do
      sign_in(editor)

      patch constructors_project_person_attendance_path(project, person, attendance),
            params: { person_attendance: { hours: '6' } }

      expect(attendance.reload.hours).to eq(6)
    end

    it 'un viewer no puede: ve las horas pero no las escribe' do
      sign_in(viewer)

      patch constructors_project_person_attendance_path(project, person, attendance),
            params: { person_attendance: { hours: '6' } }

      expect(response).to have_http_status(:see_other)
      expect(flash[:alert]).to include('No tenés permiso')
      expect(attendance.reload.hours).to be_nil
    end

    it 'alguien de otra obra ni siquiera la encuentra' do
      sign_in(outsider)

      patch constructors_project_person_attendance_path(project, person, attendance),
            params: { person_attendance: { hours: '6' } }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE destroy' do
    let!(:attendance) { create(:person_attendance, project_person: person) }

    it 'deshace una marca equivocada' do
      expect {
        delete constructors_project_person_attendance_path(project, person, attendance)
      }.to change(PersonAttendance, :count).by(-1)

      expect(response).to redirect_to(constructors_project_person_path(project, person))
    end

    it 'un viewer no puede borrar marcas' do
      sign_in(viewer)

      expect {
        delete constructors_project_person_attendance_path(project, person, attendance)
      }.not_to change(PersonAttendance, :count)
    end
  end

  describe 'la ficha de persona' do
    let!(:attendance) { create(:person_attendance, project_person: person, hours: 8, occurred_at: 2.days.ago) }

    it 'muestra las horas, el total del período y el costo cuando hay tarifa' do
      person.update!(hourly_rate_cents: 450_000)
      create(:person_attendance, project_person: person, hours: '7,5', occurred_at: 1.day.ago)

      get constructors_project_person_path(project, person)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Horas')
      expect(response.body).to include('attendance_hours_total')
      expect(response.body).to include('15,5 hs')          # 8 + 7,5, con coma es-AR
      expect(response.body).to include('Costo MO · 30 días')
    end

    # El punto de todo esto: el KPI dejaba de ser un guion sólo si están los
    # dos factores. Con horas y sin tarifa sigue siendo guion, no un número.
    it 'con horas pero sin tarifa muestra guion y dice qué falta' do
      person.update!(hourly_rate_cents: nil)

      get constructors_project_person_path(project, person)

      expect(response.body).to include('falta la tarifa por hora')
    end

    it 'con tarifa pero sin horas también muestra guion' do
      attendance.update!(hours: nil)
      person.update!(hourly_rate_cents: 450_000)

      get constructors_project_person_path(project, person)

      expect(response.body).to include('sin horas cargadas en las marcas')
    end

    it 'un viewer ve las horas pero no el input para editarlas' do
      sign_in(viewer)

      get constructors_project_person_path(project, person)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('8 hs')
      expect(response.body).not_to include('person_attendance[hours]')
    end
  end
end
