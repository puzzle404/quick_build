# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this app is

QuickBuild is a Rails 8 platform originally scoped as a materials marketplace (buyers, sellers, companies, products, orders), but the **current, active focus is the Constructor Operating System**: a project-management and cost-control tool for construction companies ("constructores"). The marketplace data model and routes already exist in the codebase (see "Marketplace / e-commerce" below) but the product roadmap treats them as paused — don't let them distract from constructor-namespace work unless explicitly asked.

`AGENTS.md` (checked into the repo root) documents the product vision in more detail but is **stale in places** — most notably it says auth is "Devise-based" and describes acts_as_tenant as the multi-tenancy mechanism; neither is true today (see below). Treat this file (CLAUDE.md) as the authoritative, current source; AGENTS.md's tool-choice guidance (when to reach for a decorator vs. a service vs. a ViewComponent) is still good and is summarized under "Code Organization Guidelines" below.

## Design System — QB OS (read this before any visual/UI work)

**The canonical visual reference for the constructor app is `design_handoff_quick_build_os/`, at the repo root — not a description, the actual pixel-accurate design.** `Quick Build OS.html` and `Stage Detail Redesign.html` are exported Claude Artifacts (self-contained, standalone HTML/React bundles — open them directly in a browser, no build step, no server needed) that the user designed with Claude specifically to define this app's look. They pin down exact color tokens (oklch, both the Graphite/light and Night/dark themes), typography (Geist + Geist Mono), spacing, component states (hover/active/disabled), and interaction patterns.

**Before making or judging any visual change in the constructor app, open the relevant handoff file first.** It's the target, not a rough sketch — if implemented UI diverges from it, that's a bug to fix, and if a requested change would diverge from it, say so explicitly instead of quietly improvising a different look. Everything below in this section (tokens, primitives, forms, the drawer system) is the CSS/ViewComponent *implementation* of what those files show; when the two disagree, the handoff file wins and the implementation should be brought in line with it.

The mobile-equivalent reference is `design_handoff_quick_build_mobile/` — `Quick Build Mobile.html` (same kind of Claude Artifact export) plus its own `README.md`, which is worth reading in full: it documents the token table, the 22 designed screens grouped by section, the `M*` component inventory (`MTabs`, `MFormRow`, `MKpi`, etc. — the direct spec for the `Qb::Mobile::*` ViewComponents), and — importantly — a mapping from each designed screen to the existing Rails controller/model that should implement it, so check that table before assuming a mobile screen needs new backend work.

Everything under the `Constructors::` namespace (`app/views/constructors/**`, `app/components/constructors/**`) MUST match this system. No exceptions, no parallel styles, no inventing a new visual language for a one-off screen.

- **Tokens, not palettes:** style with the CSS variables defined in `app/assets/tailwind/application.css` (`var(--color-ink)`, `--color-ink-2/3/4`, `--color-line`, `--color-line-2`, `--color-bg`, `--color-bg-raised`, `--color-bg-sunken`, `--color-accent`, `--color-ok/warn/bad/info`, `--font-mono`, `--radius`). Do **NOT** use raw Tailwind palette classes (`slate-*`, `indigo-*`, `emerald-*`, `rose-*`, `bg-white`, `rounded-2xl`, `shadow-sm`, etc.) in constructor UI.
- **Primitives:** reuse `Qb::*` components rather than ad-hoc markup. Non-layout primitives in `app/components/qb/`: `BtnComponent`, `PillComponent`, `BarComponent`, `StackedBarComponent`, `SparkComponent`, `IconComponent`, `MetricCellComponent`, `SectionHeadComponent`, `TabsComponent`, `TabbedPanelComponent`, `StatusDotComponent`, `AvatarComponent`, `PaginationComponent`, `FilterChipComponent`, `FormGroupComponent`, `DataGridComponent`, `MenuComponent`, `DrawerComponent`, `FileFieldComponent`, `MoneyFieldComponent`, `SpinnerComponent`, `DrawerSkeletonComponent`, `ToastStackComponent` + `ToastComponent`. Layout chrome in `app/components/qb/layout/`: `SidebarComponent` (desktop rail — brand + account switcher unified into one button; the per-project section list was removed from here because it duplicated the tabs above the content), `TopbarComponent`, `BottomNavComponent` + `MobileSheetComponent` (mobile-narrow "Más" sheet), `CmdPaletteComponent`, `TweaksPanelComponent`, `AlertsPanelComponent`, and the shared `Navigation` module (mixed into both `SidebarComponent` and `BottomNavComponent`/`MobileSheetComponent` so primary + per-project nav data doesn't diverge between them). Build any new shared UI as a `Qb::*` primitive rather than ad-hoc markup — check `/dev/styleguide` and the handoff files first to see if something already covers it.
- **Buttons:** `Qb::BtnComponent` is the ONLY button in constructor UI. `Ui::ButtonComponent` is legacy/marketing — do not use it under `Constructors::`.
- **Forms:** use the canonical form classes (`.qb-field`, `.qb-label`, `.qb-input`, `.qb-select`, `.qb-textarea`, `.qb-form-error`) from `application.css`. No per-input Tailwind. `input[type="file"]` is never rendered bare — Chrome/Safari won't let CSS restyle the native file button's color even with `::file-selector-button` + `appearance:none`, so always use `Qb::FileFieldComponent.new(form:, method:, ...)` instead of `f.file_field` directly (pass `compact: true` for an inline toolbar spot). **Money inputs** are never a bare `number_field`/`text_field`: use `Qb::MoneyFieldComponent.new(form:, method: :xxx_pesos, value: qb_money_input_value(cents))` (mobile: `Qb::Mobile::FormAmountRowComponent`, which carries the same mask). It shows a `$` prefix and formats es-AR while typing (`qb--money-input`: `1.500.000,50`; the main-keyboard `.` is ignored because thousands are auto-grouped, and the numpad `.` becomes the decimal comma). The attribute is always the virtual `*_pesos` one, parsed server-side with `Money::ArsParser` — never have users type `*_cents`. The component always passes `value:` explicitly because most models have no `*_pesos` getter.
- **Feedback & loading:** flash messages render as toasts (`Qb::ToastStackComponent` in both constructor layouts; `#qb_toasts` always exists so a turbo_stream can `append` to it). Loading states are global and need no per-view work: `qb--loading` on `<body>` shows the Turbo progress bar (accent color, 300 ms), a Blocks overlay over the content area on slow visits (500 ms, including full reloads via `beforeunload`, with downloads excluded), and marks the submitting button busy (ring + disabled — this is also the double-submit guard). The global drawer clones `Qb::DrawerSkeletonComponent` into the frame when a GET takes >200 ms. To see them locally, `?_delay=2` (development only, cookie-sticky; `?_delay=0` turns it off) delays every response.
- **Money & dates:** use `qb_fmt_ars` / `qb_fmt_ars_full` / `qb_fmt_cents` / `qb_fmt_pct` / `qb_fmt_date_short` / `qb_fmt_datetime_short` (`app/helpers/quickbuild_helper.rb`). Never `number_to_currency` in constructor UI.
- **Right-side drawer, not modals:** every "new"/"edit" action in the constructor app opens in the single global right-side drawer, not a modal or a full-page navigation. One `<turbo-frame id="drawer">` is mounted once in `layouts/constructor.html.erb`; individual views populate it via `content_for(:drawer)` (never declare a second `<turbo-frame id="drawer">` on a page). Chrome (header/body/optional footer) comes from `Qb::DrawerComponent`, sized `:md`(480px, rare)/`:lg`(560px, the standard for forms)/`:xl`(880px, content viewers like the library viewer or material-list detail — genuinely need the room, don't use `:lg` there). The `qb--drawer` Stimulus controller runs in two modes: frame-driven (global instance, watches the frame via `MutationObserver` — NOT `turbo:frame-load`, which doesn't fire for `turbo_stream` swaps) and click-driven (self-contained components with no `:new` route, e.g. "Invitar miembro"). It keeps a small client-side navigation history: drilling into a new view from an already-open drawer pushes the previous URL, so the header's `‹` back button and every "Cancelar" button (they call the same `back()` action) return to the previous view instead of closing the whole panel; at the root level `back()` degrades to a full close, same as the `×`/backdrop/Escape. `data-controller="qb--drawer"` must live on `<body>` — a local wrapper div shadows the global instance and breaks every click-to-open trigger elsewhere on the page. The global instance is flagged with `data-qb--drawer-global-value="true"`, not detected by "has a frame target", because during a render Turbo connects the new `<body>` while the permanent shell is still a placeholder. The drawer **persists**: the open view is mirrored in `?drawer=<path>` (so F5 reopens it), and the shell (`#qb_drawer_shell`) is `data-turbo-permanent`, so a `turbo_stream.refresh` NOT caused by the drawer keeps it open with whatever the user typed. It still closes on a real navigation and when the refresh follows the drawer's own form submission. Frame listeners are attached through `frameTargetConnected`/`frameTargetDisconnected` because Turbo swaps the frame in after `connect`. The overlay behind drawers, sheets and palettes is `var(--color-scrim)` — never derive a scrim from `--color-ink` (in Night the ink is near-white and the overlay came out white).
- **Out of scope:** the public/marketing layout (`layouts/marketing`, home/products/cart/companies) keeps its own design and the `Ui::*` marketing components — the handoff files above and this whole section are about the constructor app only.
- The `/dev/styleguide` page catalogs the canonical primitives live in the running app — check it (alongside the handoff files) before inventing UI.

## Prerequisites

- Ruby 3.2+ (repo pinned via `.ruby-version`)
- PostgreSQL
- Bundler

## Build & Development Commands

```bash
# Install dependencies
bundle install

# Database setup
bin/rails db:setup      # Create, migrate, and seed
bin/rails db:seed       # Load seed data

# Development server
bin/dev                 # Runs Puma + Tailwind watcher (Procfile.dev)

# Tests (always use bundle exec) — see "Testing" below for the CI caveat
bundle exec rspec                        # Run all specs
bundle exec rspec spec/models/           # Run model specs
bundle exec rspec spec/path/to_spec.rb   # Run single file
bundle exec rspec spec/path:42           # Run specific line

# Linting / security
bundle exec rubocop                      # Check style (Omakase, no custom rules)
bundle exec rubocop -a                   # Auto-fix safe issues
bin/brakeman --no-pager                  # Security scan (also runs in CI)
bin/importmap audit                      # JS dependency audit (also runs in CI)
```

## Environment Variables

Copy `.env.example` to `.env` for development (loaded via `dotenv-rails`). Key variables:
- `OPENAI_API_KEY` — required for AI blueprint analysis (`gpt-4o-mini` via `ruby-openai`); the feature is currently paused in the UI, but the backend still needs this if you re-enable it or test the job directly.
- `GOOGLE_MAPS_API_KEY` — browser key for **Maps JavaScript API** + **Places API (New)** (or `credentials.google_maps.api_key`, which wins). It is exposed in `<meta name="google-maps-api-key">` in `layouts/constructor` and loaded lazily by `app/javascript/google_maps.js`. It is public by design, so restrict it by HTTP referrer in Google Cloud. Without it, the address still saves as plain text and maps show a notice. Newly enabled APIs take a few minutes to propagate (`ApiNotActivatedMapError` until then).
- `OPENWEATHER_API_KEY` — used by `External::WeatherFetcher` (dashboard weather widget); falls back to a "stale"/cached value if missing or the API call fails.
- `HEADFUL=1` or `SHOW_BROWSER=1` — show a real browser window during `js: true` system specs (Cuprite). Either variable being non-empty triggers headful mode.
- `CLOUDINARY_URL` — not in `.env.example` but required in any environment where `config.active_storage.service = :cloudinary` (development and production both use Cloudinary; only `test` doesn't). The `cloudinary` gem reads this itself; there's no app-level initializer.
- `QB_BASE_URL` — consumed by the iOS Hotwire Native shell (`ios/QuickBuildMobile/AppEnvironment.swift`), not by the Rails app itself; defaults to `http://localhost:3000`.

## Architecture Overview

### Rails 8 application — NOT actually row-based multi-tenant

Despite `acts_as_tenant` being in the `Gemfile`, it is **declared but not wired up**: only `Product` calls `acts_as_tenant(:company)` (`app/models/product.rb`), and nothing in the app ever sets `ActsAsTenant.current_tenant` — there's no `set_current_tenant_through_filter`, no controller `before_action`, nothing. `ProductsController` scopes products manually (`@company.products`) instead of relying on the gem's automatic tenant scoping. Treat `acts_as_tenant` as effectively inert; if you need real per-company row isolation for `Product`, you'll need to actually wire it (`ActsAsTenant.current_tenant = ...` per request) — it isn't happening today.

**Real data isolation in the constructor app is authorization-based, not tenant-based**: `Project` implements its own role system (`Project#role_for(user)`, `ROLE_RANK = {viewer:1, editor:2, admin:3, owner:4}`, `scope :accessible_by`) and `Constructors::BaseController#find_project!` always resolves a project through `current_user.accessible_projects` — never `Project.find` directly. Pundit policies (see below) layer authorization on top of that per-project role. There is no separate "company" boundary for constructor data — a `Project` belongs to an owning `User`, not a `Company`.

Background jobs, cache, and Action Cable all run on the Solid stack (`solid_queue`, `solid_cache`, `solid_cable`) — no Redis dependency. Mission Control::Jobs is mounted at `/jobs`.

### Key Patterns

**Namespace Organization:**
- `Constructors::` namespace for all constructor features (`app/controllers/constructors/`, `app/views/constructors/`, `app/components/constructors/`) — this is where essentially all active development happens.
- Constructor views use `layouts/constructor.html.erb` (desktop/responsive) or `layouts/mobile.html.erb` (the `:mobile` Rails variant — see "Mobile, PWA & Hotwire Native" below).
- Public/marketing pages use `layouts/marketing.html.erb`.
- Legacy/embryonic e-commerce controllers (`ProductsController`, `OrdersController`, `CartsController`, `CategoriesController`) live at the root of `app/controllers/`, unnamespaced — see "Marketplace / e-commerce" below.

**Authentication & Authorization:**
- **No Devise anywhere in this app** (not in the Gemfile, not in Gemfile.lock) — despite `AGENTS.md` describing Devise-based auth. Auth is the Rails 8 `bin/rails generate authentication` pattern: `has_secure_password` on `User` (bcrypt, `password_digest` column) + a `Session` model, wired through the `Authenticable` concern (`app/controllers/concerns/authenticable.rb`).
  - The session cookie (`cookies.signed.permanent[:session_id]`) is **permanent** (~20 years) and `Session` has no `expires_at` column — sessions never expire by time, only by explicit logout (`Session#destroy`) or cascade-delete with the user. There's no remember-me toggle; every session is "permanent" by design.
  - `start_new_session_for(user)` reuses an existing `Session` row for the same `user_agent`+`ip_address` combo instead of always creating a new one.
  - Hotwire Native requests get `head :unauthorized` instead of a redirect when unauthenticated (`hotwire_native_app?`, provided by the `turbo-rails` gem's `Turbo::Native::Navigation`, not defined locally — matches `/(Turbo|Hotwire) Native/` against the user-agent).
  - `Company` has legacy `encrypted_password`/`reset_password_token`/`reset_password_sent_at`/`remember_created_at` columns from what looks like an abandoned attempt at Devise-authenticating companies directly — the model has no `devise` call and these columns are dead.
- Authorization via Pundit policies in `app/policies/`. `ApplicationPolicy` centralizes the per-project role matrix in its header comment: `viewer` (read-only) → `editor` (+ create/edit content: stages, expenses, materials, blueprints, docs, photos, attendance, notes) → `admin` ("obra admin" — + edit project data, manage team) → `owner` (+ delete the project). `User#admin?` (`platform_admin?` in policy code) always has full access regardless of project role. Key shared predicates: `project_access?`, `project_editor?`, `project_manager?`, `project_owner?`. Policies exist for `Project`, `ProjectStage`, `MaterialList` (+ `toggle_publication?` for the marketplace-visibility flag), `Expense`, `Note`, `PersonAttendance`, `ProjectMembership`, `ProjectPerson`. `Constructors::PeopleController` (the global, cross-project people view) and `StageTemplate` have no dedicated policy — they authorize inline via `constructor?` checks / ownership scopes instead.
- User roles enum: `buyer, constructor, admin, seller` (positional integer enum — `buyer` is index 0/default). Only `seller` requires a `company` (`validates :company, presence: true, if: :seller?`); `constructor`/`buyer`/`admin` all have `belongs_to :company, optional: true`.
- Role checking via `RolesHelper` (e.g., `current_user.constructor?`).

**`:mobile` request variant (not a separate app):**
- `ApplicationController#set_mobile_variant` (a `before_action`) sets `request.variant = :mobile` when `mobile_client?` is true — an OR of 5 signals: Hotwire Native user-agent, `Hotwire-Native-Visit` header, the `qb_mobile_client` cookie (set client-side by the `qb--mobile-detect` Stimulus controller based on viewport width / PWA standalone mode), a mobile UA regex, and a dev-only `?_variant=mobile` override cookie.
- Use the `mobile_variant?` helper (`request.variant.include?(:mobile)`) to branch in controllers/views — never re-implement the detection.
- Templates follow a "parallel views" pattern: `show.html.erb` + `show.html+mobile.erb` side by side, same controller action. This exists for ~33 constructor views plus the 3 shared auth screens (`sessions/new`, `registrations/{new,edit}`, `passwords/{new,edit}`) — **not** for the legacy e-commerce views (carts/categories/home/orders/pages/products have no mobile variants).
- `layouts/constructor.html.erb` is actually responsive (serves both desktop and a mobile-narrow-in-browser mode, with its own bottom nav + "Más" sheet for narrow viewports); `layouts/mobile.html.erb` is a separate, much lighter layout used for the true `:mobile` variant / Hotwire Native (no sidebar/topbar/drawer/cmd-palette, just a tab bar).

## Constructor Domain Models

Grouped by area (all under `app/models/`, 29 files total; `db/schema.rb` has 40 tables — the other 14 are ActiveStorage (3) and Solid Queue (11) internals with no app model):

**User / auth:** `User` (roles, prefs), `Session`, `Current` (`ActiveSupport::CurrentAttributes`, delegates to the session's user).

**Project / obra:** `Project` — the core entity. `enum :status, [:planned, :in_progress, :completed]`; owns its own role system (see Authorization above); `belongs_to :owner` (a `User`, not a company); decorated by `ProjectDecorator` for progress curves, health heuristics, and formatted labels.

**Planning / WBS:** `ProjectStage` (2-level WBS — root stages + one level of sub-stages, `parent`/`sub_stages`, `predecessor`/`successors`), `StageTemplate` + `StageTemplateItem` (reusable stage structures with relative day-offsets instead of absolute dates, captured from an existing project via `Constructors::Projects::StageTemplateCaptureService` and applied via `Constructors::Projects::StageTemplateService`).

**Materials — two separate, unrelated systems:**
- `MaterialList` (a curated list per project/stage; `enum :status` draft/ready_for_review/approved; `enum :source_type` manual/pdf_upload/excel_upload) + `MaterialItem` (line items) + `MaterialListPublication` (marketplace-visibility flag, `publish!`/`unpublish!`).
- `Material` / `ConstructionItem` / `ConstructionItemMaterial` — a separate reference catalog ("construction items" like "Muro Ladrillo Hueco 12" with their material/quantity recipe), used when annotating a blueprint. Not linked to `MaterialList`/`MaterialItem` yet; the AI blueprint analysis code has an explicit TODO to eventually match detected elements against `ConstructionItem`.

**Costs:** `Expense` (`enum :category` labor/materials_misc/rentals/other; optional link to a `MaterialList`, meaning "this expense pays for that list"; `has_one_attached :receipt`).

**Workforce:** `ProjectPerson` (a worker on a project) + `PersonAttendance` (a shift; cost computed from `hours × hourly_rate_cents`).

**Blueprints / AI:** `Blueprint` (`has_one_attached :file`, jsonb `measurements` with a GIN index, `scale_ratio`) + `AiBlueprintAnalysis` (manual state machine: `queued/processing/completed/failed`; `raw_response`/`suggested_measurements` jsonb; `applied_at`). AI analysis creation is currently paused in the UI (see below) but the models/job/lib code are untouched.

**Polymorphic attachments (shared across Project and ProjectStage):** `Note` (`noteable`), `Document` (`documentable`, backed by `has_one_attached :file`), `Image` (`imageable`, one `featured` image enforced by a partial unique index).

**Marketplace (see next section):** `Product`, `Order`, `LineItem`, `Category`, `Company`.

## Marketplace / e-commerce (paused roadmap item, but the code is real)

`AGENTS.md` frames buyer/seller flows as "on the roadmap, not yet active" — but the data model, routes, and controllers already exist and are functional as a bare-bones catalog + cart:

- Models: `Product` (`acts_as_tenant(:company)`, `belongs_to :category`), `Order` (`belongs_to :user`, `state` string), `LineItem` (join), `Category` (empty besides `name`).
- Controllers at the root of `app/controllers/`: `products_controller.rb`, `orders_controller.rb`, `categories_controller.rb`, `carts_controller.rb` (+ `Cart` concern — cart lives in `session[:cart]`, never persisted to a table).
- Routes: `resources :companies { resources :products }`, `get "all_products"`, `resources :categories`, `resource :cart`, `resources :orders` — all unnamespaced, outside `constructors/`.
- `User#role` already has `buyer`/`seller` (seller requires a `company`); `MaterialListPublication`/`MaterialList#toggle_publication?` already model "publish this list so sellers can quote it" — the constructor side of a future marketplace integration is partly in place.
- **Known break:** `resources :companies` is routed but **`CompaniesController` doesn't exist** — any request to `/companies*` raises `NameError`. Nobody currently links to it, so it's latent, not user-facing.
- `db/seeds.rb` seeds sample `Category`/`Company`/`Product`/`User` records for this area.

Don't build on this without checking with the user first — it's real code but explicitly not the current product focus, and the one example above shows it isn't fully wired.

## Code Organization Guidelines

From `AGENTS.md` (still accurate):
- **Decorators** (`app/decorators/`, Draper) — presentation logic per model. `BaseDecorator` (shared `delegate_all` base) → `ProjectDecorator` (the big one: code, progress, health, curve series), `ProjectStageDecorator`, `UserDecorator`. (`HotwireDecorator` exists as unused boilerplate scaffold — ignore it.)
- **Services** (`app/services/`) — isolated business logic. Notably: `Constructors::DashboardService`/`Constructors::SearchService` (cross-cutting aggregation), `Constructors::Projects::*SearchService` (one per tab: documents/materials/people/projects/stages — all built on the shared `Support::DateRangeFilter`), `Projects::{ProgressCalculator,SpendSummary,SectionCounts,StageCounts,ActivitiesService}` (per-project computed data, several written specifically to avoid N+1 by batching into 1-3 queries), `Exports::CsvBuilder` (the one CSV generator — BOM, `;` separator, es-AR decimal comma, formula-injection escaping), `Money::ArsParser` (parses "1.500,50"-style input to cents), `External::{ExchangeRatesFetcher,WeatherFetcher}` (both cache 1h + degrade to a "stale" last-known value on failure).
- **Interactors** — the `interactor` gem is in the `Gemfile` but **nothing in the app uses it** (no `app/interactors/`, no `include Interactor` anywhere). Multi-step orchestration is done with plain service objects instead (e.g. `Ai::Services::BlueprintAnalyzer` acts as a de facto organizer). Treat this as a dependency to eventually remove or an unused pattern to adopt, not as an active convention.
- **ViewComponents** (`app/components/`) — reusable, testable view logic with slots/props. This is the dominant pattern in the view layer: 110+ `.rb` files under `app/components/`. See "Frontend Stack" below for the QB OS inventory.
- **Helpers** — small transversal view utilities. `QuickbuildHelper` (`qb_fmt_*` formatters — see design system rules below), `RolesHelper`, `Constructors::ProjectsHelper` (status badges, date labels). (`ApplicationHelper` is legacy/e-commerce; `HotwireHelper` is an empty unused scaffold.)
- **Partials** — simple view extraction without logic.

## AI Integration (currently paused in the UI)

Blueprint analysis uses OpenAI (`gpt-4o-mini`, vision) via the `ruby-openai` gem. **As of the last change here, every UI trigger to start a new AI analysis has been removed** (the "Análisis IA" panel in the blueprint workspace, "Nuevo análisis"/"Crear primer análisis" buttons, even on the now-orphaned history pages) and the "· IA" suffix dropped from the "Planos" section name everywhere. This was a deliberate, UI-only pause — nothing below was touched, so re-enabling it later is just re-adding the buttons:

- `lib/ai/client.rb` — `Ai::Client`, thin wrapper over `OpenAI::Client` (reads `OPENAI_API_KEY`).
- `lib/ai/prompts/` — `Ai::Prompts::Base` + `Ai::Prompts::BlueprintAnalyzer` (prompt template, always asks for JSON-only output).
- `lib/ai/parsers/measurement_parser.rb` — `Ai::Parsers::MeasurementParser`, validates/normalizes the LLM's JSON into `{elements:, scale_detected:, scale_notes:, general_notes:}`.
- `lib/ai/services/{vision_processor,blueprint_analyzer}.rb` — `Ai::Services::VisionProcessor` builds the image URL + prompt and calls the client; `Ai::Services::BlueprintAnalyzer` is the de facto orchestrator (processing → parse → mark completed/failed on the `AiBlueprintAnalysis` record).
- `app/jobs/analyze_blueprint_job.rb` — `AnalyzeBlueprintJob`, the only job in the flow (Solid Queue, 3 retries with polynomial backoff), enqueued from `Constructors::Projects::Blueprints::AiAnalysesController#create`.
- The `Ai` module lives under `lib/ai/` (moved from `app/ai/` to satisfy Zeitwerk — do not move it back).

## Frontend Stack

- Hotwire (Turbo + Stimulus), ViewComponent, import maps (no bundler/Node build step for JS).
- Tailwind CSS via `tailwindcss-rails`; source at `app/assets/tailwind/application.css`, compiled by `bin/rails tailwindcss:watch` (part of `bin/dev`) to `app/assets/builds/tailwind.css`.

### Design System

See "Design System — QB OS" near the top of this file — it's mandatory for everything under `Constructors::` and takes precedence over anything below.

### Maps & project location

Maps are **Google Maps** (Leaflet/OpenStreetMap were removed — don't reintroduce them). The project address flow (`constructors/projects/_location_fields` + `project_map_controller.js`) works like PedidosYa/Airbnb:

- There is a single "Dirección de la obra" field with Places suggestions in a QB-styled dropdown below it (not inside the map).
- Picking a suggestion fills the address and centers a map that has a **fixed center pin**: the user moves the map, not the pin.
- Moving the map **never** rewrites the typed address, because the written address is the source of truth and is what gets shared (`Overview::ShareLocationComponent`: copy / WhatsApp / Google Maps). If the pin ends up more than 150 m away from the chosen address, a hint says so.
- `qb--mini-map` is the read-only map in the project rail. It waits for a non-zero size (via `ResizeObserver`) because Google draws an empty map inside hidden tabs.

### Project show page (`projects#show`)

- **Left column:** stage cards (compact) or the Gantt.
- **Right rail** (`.qb-project-rail`): 2 tabs via `Qb::TabbedPanelComponent` with `storage_key:` (the chosen tab survives refreshes) and `flush: true`.
  - **Seguimiento:** `HealthStripComponent` (real vs plan from `progress_percent`, the same number as the header KPI), S-curve, `RisksPanelComponent` (derived alerts, max 3, with optional CTA), `UpcomingDeadlinesComponent`, and `LogbookComponent` (quick note plus one timeline of notes and activity, with a Todo/Notas/Actividad filter).
  - **Datos de la obra:** `ProjectFactsComponent`, the creation data with the map; empty fields link to the edit drawer.
- **No nested scroll areas.** `qb--sticky-fit` makes the rail sticky only while it fits in the viewport; otherwise it flows with the page. A sticky rail taller than the window hid its bottom part.
- **Don't duplicate** in the rail what already has its own section tab (team, documents, per-stage status).

### Mobile, PWA & Hotwire Native

- **Mobile ViewComponents** live in `app/components/qb/mobile/` (`Qb::Mobile::*`, 19 components — `NavBarComponent`, `PageHeaderComponent`, `SectionComponent`, `CardComponent`, `RowComponent`, `PillComponent`, `TabBarComponent`, the `Form*RowComponent` family for iOS-Settings-style forms, etc.). These back the `+mobile.erb` templates — see the variant-detection rule above. This is a completely separate design system from QB OS/desktop; don't mix `Qb::*` and `Qb::Mobile::*` components in the same view.
- **PWA**: installable via Rails 8's built-in `rails/pwa` (manifest at `/manifest`, service worker at `/service-worker`). The service worker (`app/views/pwa/service-worker.js`) is deliberately minimal — network-first with an offline-page fallback, no data caching, no push notifications. Registration is `app/javascript/pwa.js`. Meta tags are centralized in the shared `layouts/_pwa_head.html.erb` partial (included by all 4 layouts).
- **Hotwire Native**: the Rails side is fairly complete — `ConfigurationsController#ios_v1`/`#android_v1` serve path-configuration JSON (modal presentation for `/new`/`/edit`, `refresh_app` after auth, etc.), `HotwireController#refresh` is the post-auth landing action. The iOS shell (`ios/QuickBuildMobile/`, no `.xcodeproj` checked in — created locally in Xcode per `ios/README.md`) is intentionally minimal: 5 native tabs, **no Strada bridge components registered yet** (`Hotwire.registerBridgeComponents([])` is empty). There's no `android/` shell, only the `android_v1` config endpoint as groundwork.
- `hotwire_native_app?`/`turbo_native_app?` are **not defined in this repo** — they come from the `turbo-rails` gem (`Turbo::Native::Navigation`, auto-included in `ActionController::Base`). Don't go looking for their definition or assume they're missing.

## Testing

**CI does not run the real test suite — this is the single most important testing fact about this repo.** `.github/workflows/ci.yml`'s `test` job runs `bin/rails db:test:prepare test test:system`, which are Minitest's Rake tasks operating on `test/` — and `test/` contains zero real test files (only the default `rails new` boilerplate and `.keep` placeholders). That job passes ("0 runs") without checking anything. The actual test suite — 130+ `_spec.rb` files (~970 examples) across models/requests/components/system/services/decorators/policies/jobs — lives in `spec/` and **is never invoked by CI**. Always run `bundle exec rspec` yourself before treating a change as verified; a green CI badge on this repo proves nothing about RSpec. (CI does correctly run Rubocop and Brakeman + `importmap audit` — lint/security are real, tests are not.)

Uses RSpec with:
- FactoryBot for test data (`spec/factories/`, 20 factories — one per major model).
- Shoulda Matchers for Rails assertions.
- WebMock (`WebMock.disable_net_connect!(allow_localhost: true)`) — external HTTP is blocked by default in tests; stub it.
- Google Maps in JS system specs: tag the example `google_maps: true` (sets a fake key) and call `stub_google_maps!` before `visit` (`spec/support/google_maps_stub.rb`: fake `importLibrary`, one canned suggestion, and `window.__gmMoveMap(lat, lng)` to simulate dragging the map). Never hit Google from specs.
- Request specs asking "did this render a drawer?" must use `body_without_templates`, not `response.body`: the constructor layout ships a `<template>` holding an inert `.qb-drawer-panel` (the loading skeleton).
- Cuprite for system specs that need JS (`driven_by :cuprite` only on specs tagged `js: true`; other system specs use plain `rack_test`). Config in `spec/support/capybara_cuprite.rb`; `HEADFUL`/`SHOW_BROWSER` (either non-empty) runs a visible browser.
- `ViewComponent::TestHelpers` + `Capybara::RSpecMatchers` included for `type: :component` specs.
- Standard transactional fixtures (`use_transactional_fixtures = true`) — there's a stale comment in `rails_helper.rb` claiming system specs clean up via "truncation hooks"; no such hooks exist, ignore that comment.
- Request specs in `spec/requests/`.

## Known rough edges (don't be surprised by these)

- Public layouts (`marketing`, `application`) carry `<meta name="turbo-visit-control" content="reload">` (except in turbo-frame responses): a Turbo visit from the constructor only swaps `<body>`, the `<html>` kept `data-theme`, and `[data-theme] .hidden { display:none !important }` hid the landing navbar after logout.
- In ViewComponents, `helpers`/`controller` aren't available before render (e.g. when another component calls `#items` to count), and `format(...)` is ViewComponent's own method. Use `Rails.application.routes.url_helpers` / `ApplicationController.helpers` / `Kernel.format` there.

- `resources :companies` is routed with no `CompaniesController` — visiting `/companies` 500s. Latent, unlinked.
- `app/controllers/dashboards_controller.rb` exists but has no route pointing to it, and references `new_user_session_path` (a Devise helper that doesn't exist here) — dead code from a prior migration.
- `acts_as_tenant` is declared on `Product` but never actually activated anywhere (no `current_tenant=` call in the whole app) — don't assume it's doing anything.
- `Company` has unused Devise-shaped columns (`encrypted_password`, `reset_password_token`, etc.) with no corresponding auth logic.
- The `interactor` gem is a dependency with zero usage in the codebase.
- `app/jobs/fake_job.rb`, `app/helpers/hotwire_helper.rb`, and `app/decorators/hotwire_decorator.rb` are unused scaffolding, not real features.
