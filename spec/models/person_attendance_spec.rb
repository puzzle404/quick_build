require 'rails_helper'

RSpec.describe PersonAttendance, type: :model do
  it { is_expected.to belong_to(:project_person) }
  it { is_expected.to validate_presence_of(:occurred_at) }

  it 'knows when it has coordinates' do
    att = build(:person_attendance, latitude: 1.0, longitude: 2.0)
    expect(att.coordinates?).to be(true)
  end

  # Las horas se tipean a mano en la obra: en es-AR el decimal es la coma y
  # sin normalizar ActiveRecord castea "7,5" a 7.0 (media hora perdida en
  # silencio, y media hora menos de costo de mano de obra).
  describe '#hours=' do
    it 'acepta la coma decimal de es-AR' do
      att = build(:person_attendance, hours: '7,5')
      expect(att.hours).to eq(BigDecimal('7.5'))
    end

    it 'acepta el punto decimal y los espacios de más' do
      expect(build(:person_attendance, hours: ' 6.25 ').hours).to eq(BigDecimal('6.25'))
    end

    it 'deja nil cuando el input llega vacío (vaciar el campo BORRA las horas)' do
      att = create(:person_attendance, hours: 8)
      att.update!(hours: '')
      expect(att.reload.hours).to be_nil
    end
  end

  describe 'validación de horas' do
    it 'acepta nil: una marca sin horas cargadas todavía es válida' do
      expect(build(:person_attendance, hours: nil)).to be_valid
    end

    it 'acepta el tope de una jornada' do
      expect(build(:person_attendance, hours: PersonAttendance::MAX_HOURS)).to be_valid
    end

    it 'rechaza 0, negativos, no-números y más de 24' do
      [ '0', '-3', 'abc', '25' ].each do |value|
        att = build(:person_attendance, hours: value)
        expect(att).not_to be_valid, "esperaba que #{value.inspect} fuera inválido"
        expect(att.errors[:hours].first).to include('entre 0 y 24')
      end
    end

    it 'responde en español, no en el inglés del fallback de i18n' do
      att = build(:person_attendance, hours: 'abc')
      att.valid?
      expect(att.errors[:hours].first).not_to include('is not a number')
    end
  end

  describe '#cost_cents' do
    let(:person) { create(:project_person, hourly_rate_cents: 450_000) }

    it 'multiplica tarifa por horas' do
      att = build(:person_attendance, project_person: person, hours: '7,5')
      expect(att.cost_cents).to eq(3_375_000)
    end

    it 'es nil sin horas (no 0: "no sé cuántas" no es "trabajó cero")' do
      expect(build(:person_attendance, project_person: person, hours: nil).cost_cents).to be_nil
    end

    it 'es nil sin tarifa' do
      sin_tarifa = create(:project_person, hourly_rate_cents: nil)
      expect(build(:person_attendance, project_person: sin_tarifa, hours: 8).cost_cents).to be_nil
    end
  end

  describe '.recent_first' do
    it 'ordena por fecha de marca descendente' do
      person = create(:project_person)
      vieja = create(:person_attendance, project_person: person, occurred_at: 3.days.ago)
      nueva = create(:person_attendance, project_person: person, occurred_at: 1.hour.ago)

      expect(person.person_attendances.recent_first.to_a).to eq([ nueva, vieja ])
    end
  end
end
