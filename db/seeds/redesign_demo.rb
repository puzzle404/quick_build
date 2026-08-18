# frozen_string_literal: true

# Quick Build OS · demo seed
# --------------------------
# Idempotent seed that creates the 7 curated projects from the Claude Design
# handoff (Torre Aurora, Casa Pilar, etc.) along with their stages, material
# lists with items, and team members. All data comes from the handoff's
# data.jsx — nothing random, nothing Faker.
#
# Load with:
#   DEMO_DATA=1 bin/rails db:seed
#
# Running again is safe — records are matched by business keys (project code,
# stage code within project, etc.) so repeated runs don't duplicate data.

puts "[redesign_demo] Starting Quick Build OS demo seed…"

constructor = User.find_by(email: 'constructor@example.com') || User.find_by(role: User.roles[:constructor])
unless constructor
  puts "[redesign_demo] No constructor user found — create one first (see db/seeds.rb)."
  return
end

# ─────────────────────────────────────────────────────────────────────
# Projects
# ─────────────────────────────────────────────────────────────────────

PROJECTS = [
  { code: 'PRJ-042', name: 'Torre Palermo · Edificio Aurora',       client: 'Inmobiliaria Delta S.A.', location: 'Av. Santa Fe 3421, CABA', lat: -34.5895, lng: -58.4113, status: :in_progress, start: '2025-11-04', due: '2026-08-18', planned_progress: 68, budget: 84_500_000, curve: [ 0, 3, 8, 15, 23, 31, 40, 48, 55, 64 ], plan: [ 0, 5, 10, 17, 26, 34, 43, 52, 60, 68 ] },
  { code: 'PRJ-039', name: 'Casa Pilar · Lote 14 Altos del Río',    client: 'Familia Ibarra',           location: 'Pilar, Buenos Aires',      lat: -34.4588, lng: -58.9144, status: :in_progress, start: '2026-01-12', due: '2026-07-30', planned_progress: 42, budget: 18_200_000, curve: [ 0, 4, 9, 14, 20, 25, 28, 30, 31 ], plan: [ 0, 6, 13, 20, 27, 33, 38, 40, 42 ] },
  { code: 'PRJ-037', name: 'Ampliación Depósito Vicente López',     client: 'Logística Norte',          location: 'V. López, BA',             lat: -34.5253, lng: -58.4730, status: :in_progress, start: '2025-09-22', due: '2026-05-10', planned_progress: 80, budget: 32_700_000, curve: [ 0, 8, 17, 28, 40, 52, 63, 71, 77, 82 ], plan: [ 0, 7, 15, 25, 38, 50, 60, 70, 76, 80 ] },
  { code: 'PRJ-044', name: 'Local Comercial Recoleta',              client: 'Grupo Estrella',           location: 'Callao 1120, CABA',        lat: -34.5955, lng: -58.3925, status: :planned,     start: '2026-05-01', due: '2026-11-15', planned_progress: 0,  budget: 14_800_000, curve: [ 0 ], plan: [ 0 ] },
  { code: 'PRJ-040', name: 'Quincho + Pileta Nordelta',             client: 'Martín Ríos',              location: 'Nordelta, Tigre',          lat: -34.4093, lng: -58.6487, status: :in_progress, start: '2025-12-05', due: '2026-04-22', planned_progress: 72, budget: 9_400_000,  curve: [ 0, 8, 18, 28, 36, 42, 46, 48 ], plan: [ 0, 12, 26, 40, 52, 62, 68, 72 ] },
  { code: 'PRJ-031', name: 'Refuncionalización Oficinas Retiro',    client: 'BancoSur',                 location: 'San Martín 140, CABA',     lat: -34.5968, lng: -58.3738, status: :completed,   start: '2025-05-10', due: '2025-12-20', planned_progress: 100, budget: 27_500_000, curve: [ 0, 11, 22, 34, 48, 62, 74, 85, 94, 100 ], plan: [ 0, 10, 22, 35, 48, 60, 72, 84, 93, 100 ] },
  { code: 'PRJ-045', name: 'Loft San Telmo · Reforma integral',     client: 'Lucía Bianchi',            location: 'Defensa 820, CABA',        lat: -34.6187, lng: -58.3712, status: :planned,     start: '2026-04-28', due: '2026-10-10', planned_progress: 8,  budget: 11_300_000, curve: [ 0, 2, 4 ], plan: [ 0, 4, 8 ] }
].freeze

projects_by_code = {}

PROJECTS.each do |p|
  project = Project.find_or_initialize_by(name: p[:name])
  project.assign_attributes(
    location:         p[:location],
    client:           p[:client],
    latitude:         p[:lat],
    longitude:        p[:lng],
    status:           p[:status],
    start_date:       Date.parse(p[:start]),
    end_date:         Date.parse(p[:due]),
    budget_cents:     p[:budget] * 100,
    progress_curve:   p[:curve],
    progress_plan:    p[:plan],
    owner:            constructor
  )
  project.save!
  projects_by_code[p[:code]] = project
end

puts "[redesign_demo] #{projects_by_code.size} proyectos sembrados."

# ─────────────────────────────────────────────────────────────────────
# Stages (only PRJ-042 has the full handoff detail; others get a light version)
# ─────────────────────────────────────────────────────────────────────

PRJ042_STAGES = [
  { code: '1',  name: 'Proyecto y gestión',         desc: 'Definición técnica y administrativa del proyecto base.', start: '2025-10-15', end_: '2025-11-30', progress: 100, lead: 'M. Fernández', budget: 2_800_000, spent: 2_640_000,
    subs: [
      { code: '1.1', name: 'Estudios preliminares',               start: '2025-10-15', end_: '2025-10-28', progress: 100 },
      { code: '1.2', name: 'Ante proyecto',                        start: '2025-10-25', end_: '2025-11-08', progress: 100 },
      { code: '1.3', name: 'Proyecto (presentación municipal)',    start: '2025-11-05', end_: '2025-11-20', progress: 100 },
      { code: '1.4', name: 'Documentación y permisos',             start: '2025-11-15', end_: '2025-11-30', progress: 100 },
      { code: '1.5', name: '3D y visualizaciones',                 start: '2025-11-10', end_: '2025-11-25', progress: 100 }
    ] },
  { code: '2',  name: 'Movimiento de suelos',       desc: 'Nivelación, excavación y retiro de tierra.',            start: '2025-11-04', end_: '2025-11-22', progress: 100, lead: 'R. Díaz',      budget: 3_800_000,  spent: 3_720_000 },
  { code: '3',  name: 'Fundaciones',                desc: 'Platea, zapatas y bases para la estructura.',           start: '2025-11-18', end_: '2025-12-14', progress: 100, lead: 'R. Díaz',      budget: 6_200_000,  spent: 6_310_000 },
  { code: '4',  name: 'Estructura',                 desc: 'Columnas, losas y vigas de hormigón armado.',           start: '2025-12-08', end_: '2026-02-20', progress: 100, lead: 'F. López',     budget: 14_100_000, spent: 14_260_000,
    subs: [
      { code: '4.1', name: 'Columnas subsuelo', start: '2025-12-08', end_: '2026-01-04', progress: 100 },
      { code: '4.2', name: 'Losas 1°–3°',       start: '2026-01-02', end_: '2026-01-30', progress: 100 },
      { code: '4.3', name: 'Columnas 4°–6°',    start: '2026-01-28', end_: '2026-02-20', progress: 100 }
    ] },
  { code: '5',  name: 'Mampostería',                desc: 'Muros interiores y exteriores, tabiques.',              start: '2026-02-10', end_: '2026-04-05', progress: 78,  lead: 'M. Pérez',     budget: 7_400_000,  spent: 5_780_000 },
  { code: '6',  name: 'Instalaciones sanitarias',   desc: 'Cañerías de agua fría, caliente y desagües.',           start: '2026-02-25', end_: '2026-04-20', progress: 62,  lead: 'J. Silva',     budget: 4_900_000,  spent: 3_050_000 },
  { code: '7',  name: 'Instalaciones eléctricas',   desc: 'Cañerías, cableado y tableros.',                         start: '2026-03-02', end_: '2026-04-28', progress: 54,  lead: 'J. Silva',     budget: 5_600_000,  spent: 3_020_000 },
  { code: '8',  name: 'Revoques',                   desc: 'Revoques gruesos y finos en interior y exterior.',      start: '2026-04-10', end_: '2026-05-20', progress: 12,  lead: 'M. Pérez',     budget: 3_800_000,  spent: 460_000 },
  { code: '9',  name: 'Contrapisos y carpetas',     start: '2026-04-22', end_: '2026-05-30', progress: 0,   lead: 'R. Díaz',      budget: 2_400_000 },
  { code: '10', name: 'Cielorrasos',                start: '2026-05-15', end_: '2026-06-20', progress: 0,   lead: 'M. Pérez',     budget: 2_100_000 },
  { code: '11', name: 'Pisos y revestimientos',     start: '2026-05-25', end_: '2026-07-10', progress: 0,   lead: 'A. Gómez',     budget: 5_800_000 },
  { code: '12', name: 'Carpinterías',               start: '2026-06-10', end_: '2026-07-15', progress: 0,   lead: 'A. Gómez',     budget: 4_400_000 },
  { code: '13', name: 'Pintura',                    start: '2026-07-01', end_: '2026-08-05', progress: 0,   lead: 'C. Ruiz',      budget: 2_700_000 },
  { code: '14', name: 'Entrega y limpieza final',   start: '2026-08-08', end_: '2026-08-18', progress: 0,   lead: 'M. Fernández', budget: 900_000 }
].freeze

stages_total = 0

def seed_stage!(project, attrs, parent: nil, position:)
  stage = project.project_stages.find_or_initialize_by(name: attrs[:name], parent_id: parent&.id)
  stage.assign_attributes(
    description:  attrs[:desc],
    start_date:   attrs[:start] && Date.parse(attrs[:start]),
    end_date:     attrs[:end_] && Date.parse(attrs[:end_]),
    progress:     attrs[:progress].to_i,
    lead:         attrs[:lead],
    budget_cents: (attrs[:budget].to_i * 100),
    spent_cents:  (attrs[:spent].to_i * 100),
    position:     position
  )
  stage.save!
  stage
end

prj042 = projects_by_code['PRJ-042']
if prj042
  PRJ042_STAGES.each_with_index do |attrs, idx|
    root = seed_stage!(prj042, attrs, position: idx + 1)
    stages_total += 1
    Array(attrs[:subs]).each_with_index do |sub, s_idx|
      seed_stage!(prj042, sub, parent: root, position: s_idx + 1)
      stages_total += 1
    end
  end
end

# Light stage templates for other projects
LIGHT_TEMPLATE = [
  { code: '1', name: 'Proyecto y gestión',     start_offset: 0,   duration: 30, progress: 100, lead: 'M. Fernández', budget: 1_500_000 },
  { code: '2', name: 'Movimiento de suelos',   start_offset: 20,  duration: 15, progress: 100, lead: 'R. Díaz',      budget: 2_000_000 },
  { code: '3', name: 'Fundaciones',            start_offset: 30,  duration: 30, progress: 80,  lead: 'R. Díaz',      budget: 3_500_000 },
  { code: '4', name: 'Estructura',             start_offset: 55,  duration: 60, progress: 40,  lead: 'F. López',     budget: 5_800_000 },
  { code: '5', name: 'Mampostería',            start_offset: 100, duration: 45, progress: 0,   lead: 'M. Pérez',     budget: 3_200_000 },
  { code: '6', name: 'Terminaciones',          start_offset: 140, duration: 40, progress: 0,   lead: 'C. Ruiz',      budget: 4_100_000 }
].freeze

projects_by_code.each do |code, project|
  next if code == 'PRJ-042'
  next if project.status.to_s == 'planned' && project.start_date > Date.current

  LIGHT_TEMPLATE.each_with_index do |attrs, idx|
    start_d = project.start_date + attrs[:start_offset].days
    end_d   = start_d + attrs[:duration].days
    seed_stage!(project, {
      name: attrs[:name], desc: nil,
      start: start_d.to_s, end_: end_d.to_s,
      progress: attrs[:progress], lead: attrs[:lead],
      budget: attrs[:budget], spent: (attrs[:budget] * attrs[:progress] / 100)
    }, position: idx + 1)
    stages_total += 1
  end
end

puts "[redesign_demo] #{stages_total} etapas sembradas."

# ─────────────────────────────────────────────────────────────────────
# People (team)
# ─────────────────────────────────────────────────────────────────────

TEAM = [
  { name: 'Rodrigo Díaz',   role: 'Capataz · Movimiento de suelos',    phone: '+54 9 11 4022-1138' },
  { name: 'Federico López', role: 'Encargado · Estructura',            phone: '+54 9 11 3912-4411' },
  { name: 'Martín Pérez',   role: 'Oficial · Mampostería',             phone: '+54 9 11 5510-8823' },
  { name: 'Javier Silva',   role: 'Instalador · Sanitaria/eléctrica',  phone: '+54 9 11 6022-1092' },
  { name: 'Agustín Gómez',  role: 'Oficial · Pisos y carpintería',     phone: '+54 9 11 2914-7761' },
  { name: 'Carla Ruiz',     role: 'Oficial · Pintura',                 phone: '+54 9 11 7720-3344' },
  { name: 'Santiago Costa', role: 'Ayudante general',                  phone: '+54 9 11 5122-9981' },
  { name: 'Nicolás Vega',   role: 'Ayudante general',                  phone: '+54 9 11 6011-4420' }
].freeze

people_total = 0

projects_by_code.values.each do |project|
  count_for_project = project.status.to_s == 'completed' ? 0 : [ TEAM.size, project.project_stages.count + 1 ].min
  TEAM.first(count_for_project).each do |t|
    person = project.project_people.find_or_initialize_by(full_name: t[:name])
    person.assign_attributes(role_title: t[:role], phone: t[:phone], status: :active, start_date: project.start_date)
    person.save!
    people_total += 1
  end
end

puts "[redesign_demo] #{people_total} personas asignadas."

# ─────────────────────────────────────────────────────────────────────
# Material lists (only PRJ-042 and PRJ-039 get curated lists)
# ─────────────────────────────────────────────────────────────────────

MATERIAL_LISTS = {
  'PRJ-042' => [
    { stage_code: '3', name: 'Hormigón y hierros · Platea fundaciones', notes: 'Lista base para hormigón H21 y acero ADN 420.', status: :approved, source_type: :manual,
      items: [
        { name: 'Hierro ø12 12m ADN 420', description: 'Columnas principales', quantity: 420, unit: 'barra', cents: 2_010_000 },
        { name: 'Hierro ø16 12m ADN 420', description: 'Columnas de borde',    quantity: 140, unit: 'barra', cents: 3_680_000 },
        { name: 'Hormigón H21 elaborado', description: 'Platea + zapatas',     quantity: 140, unit: 'm³',    cents: 3_730_000 }
      ] },
    { stage_code: '4', name: 'Hierros · Columnas y losas 1°–3°', notes: 'Cómputo con IA desde plano A-03 rev.1.', status: :approved, source_type: :pdf_upload,
      items: [
        { name: 'Hierro ø6 12m ADN 420',  description: 'Estribos columnas y vigas', quantity: 180, unit: 'barra', cents: 620_000 },
        { name: 'Hierro ø8 12m ADN 420',  description: 'Estribos principales',      quantity: 640, unit: 'barra', cents: 912_000 },
        { name: 'Hierro ø10 12m ADN 420', description: 'Armado de losas',           quantity: 320, unit: 'barra', cents: 1_410_000 },
        { name: 'Hierro ø20 12m ADN 420', description: 'Vigas principales',         quantity: 68,  unit: 'barra', cents: 5_740_000, notes: 'Revisar con calculista' },
        { name: 'Alambre recocido Nº14',  description: 'Atadura de armaduras',      quantity: 40,  unit: 'kg',    cents: 380_000 },
        { name: 'Mallas Q188',            description: 'Losas y contrapisos',       quantity: 180, unit: 'u',     cents: 1_820_000 }
      ] },
    { stage_code: '5', name: 'Ladrillos y morteros · Muros interiores', status: :approved, source_type: :manual,
      items: [
        { name: 'Ladrillo hueco 18×18×33',     description: 'Muros de carga', quantity: 9_200, unit: 'u',     cents: 720 },
        { name: 'Cemento Loma Negra CPN40',    description: 'Mortero',        quantity: 220,   unit: 'bolsa', cents: 980_000 },
        { name: 'Cal hidráulica 25kg',         description: 'Mortero',        quantity: 160,   unit: 'bolsa', cents: 420_000 },
        { name: 'Arena fina granel',           description: 'Mortero',        quantity: 18,    unit: 'm³',    cents: 340_000 }
      ] },
    { stage_code: '5', name: 'Ladrillos vistos · Fachada sur', notes: 'Pendiente definir proveedor. 3 cotizaciones pedidas.', status: :ready_for_review, source_type: :manual,
      items: [
        { name: 'Ladrillo visto rojo 6×12×25', description: 'Primera calidad',    quantity: 3_200, unit: 'u',     cents: 48_000 },
        { name: 'Cemento Portland CPN 50kg',   description: 'Mortero de asiento', quantity: 40,    unit: 'bolsa', cents: 980_000, notes: 'Cotización pendiente' }
      ] },
    { stage_code: '6', name: 'Cañerías PVC y accesorios', status: :approved, source_type: :excel_upload,
      items: [
        { name: 'Caño PVC 110mm 4m desagüe', description: 'Red cloacal', quantity: 88, unit: 'u', cents: 1_240_000 },
        { name: 'Curva 90° PVC 110mm',       description: 'Accesorios',  quantity: 44, unit: 'u', cents: 320_000 },
        { name: 'Ramal T 110mm',             description: 'Accesorios',  quantity: 22, unit: 'u', cents: 410_000 }
      ] },
    { stage_code: '8', name: 'Cemento, cal y arena · Revoques', notes: 'Cargar antes de próxima semana.', status: :draft, source_type: :manual,
      items: [
        { name: 'Cemento Portland CPN 50kg', quantity: 60, unit: 'bolsa', cents: 980_000 },
        { name: 'Cal hidráulica 25kg',       quantity: 40, unit: 'bolsa', cents: 420_000 },
        { name: 'Arena fina',                description: 'Granel', quantity: 8, unit: 'm³', cents: 420_000 }
      ] }
  ],
  'PRJ-039' => [
    { stage_code: nil, name: 'Herramientas y consumibles · Obra', notes: 'Lista general no asociada a una etapa.', status: :approved, source_type: :manual,
      items: [
        { name: 'Carretilla reforzada', quantity: 3, unit: 'u', cents: 4_500_000 },
        { name: 'Pala ancha',           quantity: 6, unit: 'u', cents: 850_000 },
        { name: 'Cinta métrica 5m',     quantity: 8, unit: 'u', cents: 320_000 }
      ] }
  ]
}.freeze

lists_total = 0
items_total = 0

MATERIAL_LISTS.each do |project_code, lists|
  project = projects_by_code[project_code]
  next unless project

  lists.each do |list_data|
    stage = list_data[:stage_code] && project.project_stages.find_by(name: PRJ042_STAGES.find { |s| s[:code] == list_data[:stage_code] }&.dig(:name), parent_id: nil)
    list = project.material_lists.find_or_initialize_by(name: list_data[:name])
    list.assign_attributes(
      notes:          list_data[:notes],
      status:         list_data[:status],
      source_type:    list_data[:source_type],
      author:         constructor,
      project_stage:  stage
    )
    list.save!
    lists_total += 1

    list_data[:items].each do |item_data|
      item = list.material_items.find_or_initialize_by(name: item_data[:name])
      item.assign_attributes(
        description:          item_data[:description],
        quantity:             item_data[:quantity],
        unit:                 item_data[:unit],
        estimated_cost_cents: item_data[:cents],
        notes:                item_data[:notes]
      )
      item.save!
      items_total += 1
    end
  end
end

puts "[redesign_demo] #{lists_total} listas con #{items_total} ítems."

# ─────────────────────────────────────────────────────────────────────
# Expenses — gastos demo para PRJ-042
# ─────────────────────────────────────────────────────────────────────

prj042 = projects_by_code['PRJ-042']

if prj042
  stage_mamposteria = prj042.project_stages.root.find_by(name: 'Mampostería')
  stage_estructura   = prj042.project_stages.root.find_by(name: 'Estructura')

  # Gasto 1: Scoped a la etapa de Mampostería
  if stage_mamposteria
    Expense.find_or_initialize_by(
      project:       prj042,
      project_stage: stage_mamposteria,
      incurred_on:   Date.parse('2026-03-15')
    ).tap do |e|
      e.assign_attributes(
        amount_cents: 1_850_000_00,
        category:     :materials_misc,
        description:  'Compra de ladrillos huecos 18×18×33 para muros interiores — partida 2',
        author:       constructor
      )
      e.save!
    end
  end

  # Gasto 2: Scoped solo al proyecto (sin etapa)
  Expense.find_or_initialize_by(
    project:       prj042,
    project_stage: nil,
    incurred_on:   Date.parse('2026-04-02')
  ).tap do |e|
    e.assign_attributes(
      amount_cents: 3_200_000_00,
      category:     :labor,
      description:  'Pago de jornales semana 13 — cuadrilla de mampostería y sanitarios',
      author:       constructor
    )
    e.save!
  end

  # Gasto 3: Alquiler de andamio (proyecto-scoped)
  Expense.find_or_initialize_by(
    project:       prj042,
    project_stage: nil,
    incurred_on:   Date.parse('2026-02-28')
  ).tap do |e|
    e.assign_attributes(
      amount_cents: 420_000_00,
      category:     :rentals,
      description:  'Alquiler de andamio tubular por 30 días — fachada sur',
      author:       constructor
    )
    e.save!
  end

  puts "[redesign_demo] Gastos demo sembrados para #{prj042.name}."
end

# ─────────────────────────────────────────────────────────────────────
# Notes — notas demo para PRJ-042
# ─────────────────────────────────────────────────────────────────────

if prj042
  stage_estructura = prj042.project_stages.root.find_by(name: 'Estructura')

  # Nota 1: sobre el proyecto
  Note.find_or_initialize_by(
    noteable: prj042,
    title:    'Reunión de avance — abril 2026'
  ).tap do |n|
    n.assign_attributes(
      body:   "Se realizó la reunión mensual con el comitente Inmobiliaria Delta S.A.\n\n" \
              "Puntos clave:\n" \
              "- El avance de mampostería alcanzó el 78%, levemente por debajo del plan (80%).\n" \
              "- Se aprobó el cambio de proveedor de ladrillos vistos para la fachada sur.\n" \
              "- Próxima entrega parcial estimada para el 20 de mayo de 2026.\n\n" \
              "Acción: M. Fernández coordina actualización del cronograma con F. López.",
      author: constructor
    )
    n.save!
  end

  # Nota 2: sobre la etapa de Estructura
  if stage_estructura
    Note.find_or_initialize_by(
      noteable: stage_estructura,
      title:    'Observación de inspector — losas 1°–3°'
    ).tap do |n|
      n.assign_attributes(
        body:   "El inspector de obra constató que las losas de 1° a 3° piso están dentro de " \
                "tolerancia según plano A-03 rev.1. Se aprobó el hormigonado de losa 3° para el " \
                "jueves 30/01/2026.\n\n" \
                "Nota: verificar curado mínimo 7 días antes de cargar andamio superior.",
        author: constructor
      )
      n.save!
    end
  end

  puts "[redesign_demo] Notas demo sembradas para #{prj042.name}."
end

# ─────────────────────────────────────────────────────────────────────
# Predecessor — Estructura precede a Instalaciones sanitarias
# Estructura end: 2026-02-20  /  Inst. sanitarias start: 2026-02-25
# ─────────────────────────────────────────────────────────────────────

if prj042
  etapa_estructura   = prj042.project_stages.root.find_by(name: 'Estructura')
  etapa_sanitarias   = prj042.project_stages.root.find_by(name: 'Instalaciones sanitarias')

  if etapa_estructura && etapa_sanitarias && etapa_sanitarias.predecessor_id.nil?
    etapa_sanitarias.update!(predecessor: etapa_estructura)
    puts "[redesign_demo] Predecesora: '#{etapa_estructura.name}' → '#{etapa_sanitarias.name}'."
  end
end

# ─────────────────────────────────────────────────────────────────────
# Featured image — si PRJ-042 ya tiene imágenes, marcar la primera
# ─────────────────────────────────────────────────────────────────────

if prj042
  first_image = prj042.images.where(featured: false).first || prj042.images.first
  if first_image && !prj042.images.where(featured: true).exists?
    first_image.update!(featured: true)
    puts "[redesign_demo] Imagen destacada asignada para #{prj042.name}."
  else
    puts "[redesign_demo] Sin imágenes adjuntas — se omite imagen destacada."
  end
end

puts "[redesign_demo] Demo seed completo ✓"
