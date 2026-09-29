# Diseño — Implementación de cambios reunión plataforma constructor 21-05-2026

**Fecha:** 2026-05-22
**Estado:** Aprobado para implementación
**Fuente:** `Resumen reunion plataforma constructor 21.05.2026.docx`

## Contexto

La reunión del 21-05-2026 ratifica el rediseño actual ("ClaudeAI") y define un conjunto de cambios sobre las pantallas de **dashboard global**, **dashboard de obra** y **etapas** que habilitan el siguiente paso del producto: salir a validar con profesionales del rubro. Este spec cubre todos los ítems del meeting en un único entregable, agrupado en fases.

Banners publicitarios se dejan **fuera de scope** por decisión del usuario.

## Resumen de decisiones

| Tema | Decisión |
|---|---|
| Alcance | Un solo spec + plan |
| Gastos | Modelo `Expense` simple con foto de recibo |
| Notas | Modelo `Note` polymorphic simple |
| Numbering listas | Correlativo por proyecto (`#1`, `#2`...) |
| Dependencias entre etapas | Finish-to-Start con 1 predecesora |
| Cálculo Gantt | Solo validación (no auto-derivación) |
| Banners | Fuera de scope |
| Tipo de cambio | USD oficial + blue (dolarapi.com), cache 1h |
| Clima | OpenWeather 5 días por lat/lng, cache 1h |
| % avance del proyecto | Promedio ponderado por duración de stages raíz |
| Estrategia de entrega | "Riesgo primero" — modelos antes que UI |

## Estado actual vs requisitos del meeting

| # | Requisito | Estado | Acción |
|---|---|---|---|
| 1 | Dashboard global: métricas + tarjetas | ✓ Existe | — |
| 2 | Dashboard global: banners | ✗ | **Fuera de scope** |
| 3 | Dashboard global: tipo de cambio | ✗ | Agregar widget |
| 4 | Dashboard obra: info completa | ◐ | Completar header |
| 5 | Dashboard obra: banners | ✗ | **Fuera de scope** |
| 6 | Dashboard obra: clima | ✗ | Agregar widget |
| 7-8 | Etapas y sub-etapas (1 nivel) | ✓ Existe | — |
| 9 | Listas de materiales por (sub-)etapa | ◐ | Backend ya tiene `project_stage_id` en `material_lists`; falta mostrarlas anidadas dentro del stage detail (sección 3.1) |
| 10 | Gastos dentro de etapa, fuera de listas | ✗ | Modelo `Expense` |
| 11 | Notas en etapa y obra | ✗ | Modelo `Note` polymorphic |
| 12 | Fotos en etapa y obra | ✓ Existe | — |
| 13 | N° identificatorio en listas | ✗ | Agregar `MaterialList#number` |
| 14 | Estado borrador/guardada de listas | ✓ Existe | — |
| 15 | Correlatividad entre etapas | ✗ | `ProjectStage.predecessor_id` |
| 16 | Gantt automático | ◐ | Validar fechas vs predecesora |

## Sección 1 — Modelo de datos

### Migraciones

```ruby
# 1) Expense
create_table :expenses do |t|
  t.references :project, null: false, foreign_key: true
  t.references :project_stage, foreign_key: true
  t.references :author, null: false, foreign_key: { to_table: :users }
  t.bigint :amount_cents, null: false
  t.string :currency, null: false, default: "ARS"
  t.integer :category, null: false, default: 0
  t.date :incurred_on, null: false
  t.string :description
  t.timestamps
  t.index [:project_id, :incurred_on]
  t.index [:project_stage_id, :incurred_on]
end
# + Active Storage attachment :receipt

# 2) Note polymorphic
create_table :notes do |t|
  t.references :noteable, polymorphic: true, null: false
  t.references :author, null: false, foreign_key: { to_table: :users }
  t.string :title
  t.text :body, null: false
  t.timestamps
  t.index [:noteable_type, :noteable_id, :created_at],
          name: "idx_notes_on_noteable_and_created"
end

# 3) Predecessor en stages
add_reference :project_stages, :predecessor,
              foreign_key: { to_table: :project_stages }

# 4) Numbering en material lists
add_column :material_lists, :number, :integer
add_index :material_lists, [:project_id, :number], unique: true
# Backfill: numerar por created_at ASC dentro de cada proyecto

# 5) Foto destacada en images
add_column :images, :featured, :boolean, default: false, null: false
add_index :images, [:imageable_type, :imageable_id, :featured]
```

### Modelos

- **`Expense`**: `belongs_to :project`, `belongs_to :project_stage, optional: true`, `belongs_to :author`, `has_one_attached :receipt`, `enum category: { labor: 0, materials_misc: 1, rentals: 2, other: 3 }`, `monetize :amount_cents`. `project_id` se denormaliza desde `project_stage` cuando aplica.
- **`Note`**: `belongs_to :noteable, polymorphic: true`, `belongs_to :author, class_name: "User"`. Validación: `body` presente. En `Project` y `ProjectStage`: `has_many :notes, as: :noteable, dependent: :destroy`.
- **`ProjectStage`**: agregar `belongs_to :predecessor, class_name: "ProjectStage", optional: true`. Validaciones:
  - `predecessor_must_be_same_project`
  - `predecessor_must_not_be_self_or_descendant` (no permite ciclos)
  - `start_after_predecessor_end` (cuando ambos `start_date` y `predecessor.end_date` están presentes)
- **`MaterialList`**: `before_create :assign_next_number` con `with_advisory_lock` (proyecto-scoped) para evitar races. Helper `display_number → "#3"`.
- **`Image`**: validación de unicidad de `featured: true` por `imageable` (a lo sumo una destacada).

### Reglas de cálculo

- **Gastos a la fecha del proyecto** = `expenses.sum(:amount_cents) + material_lists.approved.joins(:material_items).sum("quantity * unit_price_cents")`. Una `MaterialList.approved` **no** genera `Expenses` automáticamente — fuentes paralelas, sumadas a nivel reporte.
- **Foto de perfil** = `project.images.find_by(featured: true) || project.images.first`.

## Sección 2 — Servicios y cálculos

### Estructura

```
app/services/
├── projects/
│   ├── progress_calculator.rb
│   └── spend_summary.rb
└── external/
    ├── exchange_rates_fetcher.rb
    └── weather_fetcher.rb
```

### `Projects::ProgressCalculator`

- Toma solo `ProjectStage.root` del proyecto.
- Pondera por días de duración: `weight = (end_date - start_date).to_i`, `contribution = weight * (progress / 100.0)`.
- `project.progress_percent = sum(contribution) / sum(weight) * 100`.
- Stages sin fechas no participan.
- `total_weight == 0 → 0` (sin división por cero).
- **Fuente del `progress` de cada stage raíz**: el campo `progress` que ya existe en `project_stages` (entero 0-100). Lo edita el usuario directamente sobre la etapa raíz. Auto-calcular el `progress` de una raíz a partir de sus `sub_stages` queda **fuera de scope** de esta iteración — se puede agregar después sin romper el contrato del calculator.

### `Projects::SpendSummary`

- Devuelve `{ total_cents:, by_stage: {stage_id => cents}, by_category: {...} }`.
- `by_category` solo aplica a `Expense` (las listas no tienen categoría análoga).
- Memoization a nivel instancia.

### `External::ExchangeRatesFetcher`

- Fuente: `https://dolarapi.com/v1/dolares` (sin API key).
- Devuelve `{ oficial: {compra:, venta:, fecha:}, blue: {...} }`.
- Cache: `Rails.cache.fetch("fx:dolarapi", expires_in: 1.hour)`.
- Timeout HTTP 5s. Failover: leer `"fx:dolarapi:last_known"` (sin expiración); si tampoco existe, devolver `{}` con `stale: true`.
- `Logger.warn` en fallo; no lanza excepción al caller.

### `External::WeatherFetcher`

- Fuente: `https://api.openweathermap.org/data/2.5/forecast` (5 days / 3h).
- ENV: `OPENWEATHER_API_KEY`.
- Devuelve `{ current: {temp:, icon:, description:}, days: [{date:, max:, min:, icon:, description:}] x 5 }`.
- Cache: `Rails.cache.fetch("weather:#{lat.round(2)}:#{lng.round(2)}", expires_in: 1.hour)`.
- `nil` si `lat` o `lng` faltan.
- Mismo failover que FX.

### Validación de dependencia en `ProjectStage`

```ruby
def start_after_predecessor_end
  return if predecessor.blank? || start_date.blank? || predecessor.end_date.blank?
  if start_date < predecessor.end_date
    errors.add(:start_date,
      "no puede ser anterior al fin de la etapa predecesora (#{predecessor.end_date})")
  end
end
```

Validación bloqueante (no async). Mensaje visible en el form.

## Sección 3 — UI por capas

### 3.1 Stage detail

Agregar dentro del slide-over de stage:

- **Chip de predecesora** en el header del stage (si existe).
- **Sección Gastos** (`ExpensesListComponent` + `ExpenseFormComponent`): tabla densa, agrupable por categoría, total visible. Form como slide-over QB con campos: monto, fecha, categoría, descripción, recibo (file input).
- **Sección Notas** (`NotesListComponent` + `NoteFormComponent`): inline form Turbo, lista cronológica descendente.
- **Listas de materiales**: mostrar `#1`, `#2`... junto al nombre (`display_number`).
- **Form de stage**: select de **predecesora** (otras etapas raíz del proyecto). Errores de validación visibles inline.

### 3.2 Project show — header

Reescribir `HeaderComponent`:

```
[ foto perfil ]  Nombre obra · Ubicación
                 Presupuesto $X · Inicio dd/mm/yyyy · N° días: 87
                 Gastos a la fecha $Y (Z% del presupuesto) · Avance 45%
                 [ subir foto perfil ▾ ]
```

- **Foto perfil**: uploader inline; setea `featured: true` en `Image` (callback destitula la anterior).
- **Días de obra**: `[(Date.current - project.start_date).to_i, 0].max`.
- **Gastos a la fecha**: `Projects::SpendSummary.new(project).total`.
- **% Avance**: `Projects::ProgressCalculator.new(project).percent`.
- **Tab/sección Notas** en project show usando los mismos componentes polymorphic.

### 3.3 Dashboard global

Agregar widget `Constructors::Dashboard::ExchangeRatesComponent` arriba a la derecha. Muestra USD oficial y blue (compra/venta), última actualización relativa, ícono de aviso si `stale: true`. Sin spinner — la vista renderiza con cache tibio o vacío.

### 3.4 Project show — widget clima

`Constructors::Projects::WeatherComponent` en columna lateral del Overview tab. Muestra "hoy" + 4 días siguientes con ícono, max/min, descripción corta. Si `latitude` o `longitude` nil → el componente devuelve `""` (no aparece).

### 3.5 UX y permisos

- Sin SPA: Turbo Frames + Streams sobre componentes QB existentes.
- Validaciones inline (no toasts) para errores de form.
- Empty states consistentes (`qb--empty`) en cada nueva lista.
- Pundit policies `ExpensePolicy`, `NotePolicy` reutilizan lógica de `ProjectPolicy.update?` — solo el owner del proyecto puede crear/editar/borrar.

## Sección 4 — Testing strategy

### Modelo

```
spec/models/
├── expense_spec.rb
├── note_spec.rb
├── project_stage_spec.rb     # + predecessor validations
├── material_list_spec.rb     # + assign_next_number + advisory lock
└── image_spec.rb             # + featured único por imageable
```

### Servicios

```
spec/services/projects/
├── progress_calculator_spec.rb
└── spend_summary_spec.rb

spec/services/external/
├── exchange_rates_fetcher_spec.rb   # WebMock
└── weather_fetcher_spec.rb          # WebMock
```

### Request specs

```
spec/requests/constructors/projects/
├── expenses_spec.rb
├── notes_spec.rb
└── stages_spec.rb                   # + predecessor (422 con mensaje)

spec/requests/constructors/dashboard_spec.rb
                                     # + ExchangeRatesComponent stale rendering
```

### System specs (Cuprite, golden path)

```
spec/system/constructors/
├── projects/stages/
│   ├── adding_an_expense_spec.rb
│   ├── adding_a_note_to_stage_spec.rb
│   └── setting_predecessor_spec.rb
├── projects/
│   ├── project_show_header_spec.rb
│   └── adding_a_note_to_project_spec.rb
└── dashboard_with_fx_widget_spec.rb
```

### Component specs

```
spec/components/constructors/projects/
├── stages/expenses_list_component_spec.rb
├── notes_list_component_spec.rb
├── weather_component_spec.rb        # incl. lat/lng nil → render vacío
└── dashboard/exchange_rates_component_spec.rb
```

### Convenciones

- TDD obligatorio (skill `test-driven-development`): spec antes de modelo, request antes de controller, component antes de template.
- WebMock para todo HTTP externo. Sin VCR.
- FactoryBot con traits para variantes (`expense :with_receipt`, `note :on_project`).

## Sección 5 — Plan de rollout (orden de PRs)

Estrategia: "Riesgo primero" — modelos y validaciones invasivas antes que UI.

### Fase 1 — Modelos y migraciones

1. **PR #1** — `Expense` model + migration (S)
2. **PR #2** — `Note` polymorphic model + migration (S)
3. **PR #3** — `ProjectStage.predecessor_id` + validaciones (M)
4. **PR #4** — `MaterialList.number` + backfill + display (M)
5. **PR #5** — `Image.featured` + validación + helper (S)

### Fase 2 — Servicios

6. **PR #6** — `Projects::ProgressCalculator` (S)
7. **PR #7** — `Projects::SpendSummary` (S)

### Fase 3 — UI por capas

8. **PR #8** — Stage detail: Expenses CRUD (M)
9. **PR #9** — Stage + Project: Notes CRUD polymorphic (M)
10. **PR #10** — Stage form: predecessor select + validación visible (S)
11. **PR #11** — Project show header rediseñado (M)

### Fase 4 — Widgets externos

12. **PR #12** — `ExchangeRatesFetcher` + widget dashboard (M)
13. **PR #13** — `WeatherFetcher` + widget project show (M)

### Fase 5 — Cleanup

14. **PR #14** — Seed `redesign_demo` + entries en `/dev/styleguide` (S)

### Reglas

- Cada PR: tests verdes locales (RuboCop + RSpec) antes de pedir review.
- Migrations reversibles; backfills en data migrations separadas.
- Sin feature flags: servicios nuevos trabajan desde el día 1; componentes nuevos solo se montan donde se renderizan.
- Dependencias entre PRs registradas en el task tracker.
- Cada PR incluye screenshot/loom corto del happy path.

### Estimación

14 PRs · 5 fases · ~3-4 semanas con foco. Fase 1+2 es la más invasiva. Fase 4 puede paralelizarse con Fase 3 si hace falta velocidad.

## Out of scope

- Banners publicitarios (dashboard + obra).
- Sub-etapas con profundidad > 1 nivel (se mantiene el límite actual).
- Múltiples predecesoras por etapa.
- Auto-derivación de fechas de etapas a partir de la predecesora.
- Categorías de Expense como catálogo CRUD (queda como enum por ahora).
- Notas con adjuntos propios o hilos de respuesta.
- Tipo de cambio multi-moneda (UF, EUR).

## Próxima validación con el negocio

Una vez completada la Fase 3 (UI core funcionando), el meeting indica que se sale a mostrar la plataforma a profesionales del rubro. La Fase 4 (widgets externos) puede entregarse en paralelo o después de esa validación.
