# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands

```bash
# Install dependencies
bundle install

# Database setup
bin/rails db:setup      # Create, migrate, and seed
bin/rails db:seed       # Load seed data

# Development server
bin/dev                 # Start with Procfile.dev

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

### Key Patterns

**Namespace Organization:**
- `Constructors::` namespace for all constructor features (`app/controllers/constructors/`)
- Constructor views use `layouts/constructor.html.erb`
- Public/marketing pages use `layouts/marketing.html.erb`

**Authentication & Authorization:**
- Custom authentication via `Authenticable` concern (not Devise, despite AGENTS.md mention)
- Authorization via Pundit policies in `app/policies/`
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

Blueprint analysis uses OpenAI via `ruby-openai` gem:
- `app/ai/client.rb` - OpenAI client wrapper
- `app/ai/prompts/` - Prompt templates
- `app/ai/parsers/` - Response parsers
- `app/ai/services/` - AI service orchestration

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
