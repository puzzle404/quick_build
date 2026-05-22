# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Prerequisites

- Ruby 3.2+
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

# Tests (always use bundle exec)
bundle exec rspec                        # Run all specs
bundle exec rspec spec/models/           # Run model specs
bundle exec rspec spec/path/to_spec.rb   # Run single file
bundle exec rspec spec/path:42           # Run specific line

# Linting
bundle exec rubocop                      # Check style
bundle exec rubocop -a                   # Auto-fix safe issues
```

## Environment Variables

Copy `.env.example` to `.env` for development. Key variables:
- `OPENAI_API_KEY` - Required for AI blueprint analysis features
- `HEADFUL=1` or `SHOW_BROWSER=1` - Show browser during system specs (Cuprite)

## Architecture Overview

### Multi-tenant Rails 8 Application

QuickBuild is a construction project management platform with role-based access. Current focus is the **Constructor Operating System** - constructors manage projects, documentation, costs, and materials.

Row-based multi-tenancy via `acts_as_tenant`. Background jobs, cache, and Action Cable all run on the Solid stack (`solid_queue`, `solid_cache`, `solid_cable`) — no Redis dependency.

### Key Patterns

**Namespace Organization:**
- `Constructors::` namespace for all constructor features (`app/controllers/constructors/`)
- Constructor views use `layouts/constructor.html.erb`
- Public/marketing pages use `layouts/marketing.html.erb`

**Authentication & Authorization:**
- Rails 8 session-based auth: `has_secure_password` on `User` + a `Session` model, wired through the `Authenticable` concern (`app/controllers/concerns/authenticable.rb`). AGENTS.md mentions Devise — that reference is stale, ignore it.
- Authorization via Pundit policies in `app/policies/`
- User roles enum: `buyer, constructor, admin, seller` (sellers require a `company`)
- Role checking via `RolesHelper` (e.g., `current_user.constructor?`)

**Code Organization Guidelines (from AGENTS.md):**
- **Decorators** (`app/decorators/`) - Presentation logic per model (formatting dates, labels)
- **Services** (`app/services/`) - Isolated business logic, single operations
- **Interactors** - Chained processes with rollback/context control (uses `interactor` gem)
- **ViewComponents** (`app/components/`) - Reusable, testable view logic with slots/props
- **Helpers** - Small transversal view utilities
- **Partials** - Simple view extraction without logic

### Constructor Domain Models

Core entities under constructor namespace:
- `Project` - Construction works with stages, documents, blueprints
- `ProjectStage` - WBS structure with milestones
- `Blueprint` - PDF/DWG plans with AI analysis capability
- `MaterialList` / `MaterialItem` - Curated material lists
- `ProjectPerson` / `PersonAttendance` - Workforce tracking

### AI Integration

Blueprint analysis uses OpenAI via `ruby-openai` gem. The `Ai` module lives under `lib/ai/` (moved from `app/ai/` to satisfy Zeitwerk — do not move it back):
- `lib/ai/client.rb` - OpenAI client wrapper
- `lib/ai/prompts/` - Prompt templates
- `lib/ai/parsers/` - Response parsers
- `lib/ai/services/` - AI service orchestration (e.g., `BlueprintAnalyzer`, `VisionProcessor`)

### Frontend Stack

- Hotwire (Turbo + Stimulus)
- Tailwind CSS
- Import maps for JS
- ViewComponents for reusable UI

## Testing

Uses RSpec with:
- FactoryBot for test data (`spec/factories/`)
- Shoulda Matchers for Rails assertions
- Cuprite for system specs (headless Chrome)
- Request specs in `spec/requests/`
