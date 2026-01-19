# SaraAI - Testing Standards

Este documento define las convenciones para testing en SaraAI.

> [!NOTE]
> **Recordar**: Rails solo expone **Tools** (endpoints HTTP) que ElevenLabs consume.
> Los tests se enfocan en: Tools, Gateways (Google APIs), OAuth, y Models.

---

## Tabla de Contenidos

1. [Estructura de Archivos](#1-estructura-de-archivos)
2. [Convención de Nombres](#2-convención-de-nombres)
3. [Tests Unitarios](#3-tests-unitarios)
4. [Tests de Integración](#4-tests-de-integración)
5. [Tests de Sistema](#5-tests-de-sistema)
6. [Testing de Tools](#6-testing-de-tools)
7. [Mocking de Google APIs](#7-mocking-de-google-apis)
8. [Factories](#8-factories)
9. [Configuración](#9-configuración)

---

## 1. Estructura de Archivos

La estructura de `spec/` **espeja** la estructura de `app/`:

```
spec/
├── factories/                    # FactoryBot factories
│   ├── users.rb
│   └── conversations.rb
│
├── models/                       # Tests unitarios de modelos
│   ├── user_spec.rb
│   └── conversation_spec.rb
│
├── interactors/                  # Tests de interactors
│   └── tools/
│       └── calendar/
│           ├── list_events_interactor_spec.rb
│           └── list_events/
│               └── validate_user_spec.rb
│
├── services/                     # Tests de services
│   └── oauth/
│       └── google_token_refresh_service_spec.rb
│
├── gateways/                     # Tests de gateways
│   └── google/
│       └── calendar/
│           └── list_events_gateway_spec.rb
│
├── requests/                     # Tests de integración (API/Controllers)
│   ├── api/
│   │   └── tools/
│   │       ├── calendar_spec.rb
│   │       └── gmail_spec.rb
│   └── oauth/
│       └── google_spec.rb
│
├── system/                       # Tests de sistema (E2E)
│   └── oauth/
│       └── google_oauth_flow_spec.rb
│
├── support/                      # Helpers y configuración
│   ├── factory_bot.rb
│   ├── webmock.rb
│   ├── google_api_stubs.rb
│   └── shared_examples/
│       └── tool_examples.rb
│
└── cassettes/                    # VCR cassettes (opcional)
    └── google/
```

---

## 2. Convención de Nombres

### Regla Principal

> **El path del spec es idéntico al path del archivo que testea, reemplazando `app/` por `spec/` y agregando `_spec.rb`**

### Ejemplos

| Código | Test |
|--------|------|
| `app/models/user.rb` | `spec/models/user_spec.rb` |
| `app/models/conversation.rb` | `spec/models/conversation_spec.rb` |
| `app/interactors/tools/calendar/list_events_interactor.rb` | `spec/interactors/tools/calendar/list_events_interactor_spec.rb` |
| `app/gateways/google/calendar/list_events_gateway.rb` | `spec/gateways/google/calendar/list_events_gateway_spec.rb` |
| `app/controllers/api/tools/calendar_controller.rb` | `spec/requests/api/tools/calendar_spec.rb` |

---

## 3. Tests Unitarios

Tests aislados de una sola unidad de código.

### ¿Qué testear como unitario?

| Tipo | Qué testear |
|------|-------------|
| **Models** | Validaciones, métodos de instancia |
| **Interactor Steps** | Cada step individualmente (mockeando gateways) |
| **Services** | Lógica interna (mockeando gateways) |
| **Gateways** | Construcción de requests, parsing de responses |

### Ejemplo: Model

```ruby
# spec/models/conversation_spec.rb
RSpec.describe Conversation do
  describe "validations" do
    it { is_expected.to validate_presence_of(:external_chat_id) }
    it { is_expected.to validate_uniqueness_of(:external_chat_id) }
    it { is_expected.to validate_presence_of(:channel) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user).optional }
  end

  describe "#linked?" do
    context "when user is present" do
      let(:conversation) { build(:conversation, :linked) }
      it { expect(conversation.linked?).to be true }
    end

    context "when user is nil" do
      let(:conversation) { build(:conversation, user: nil) }
      it { expect(conversation.linked?).to be false }
    end
  end

  describe "#link_to_user!" do
    let(:conversation) { create(:conversation) }
    let(:user) { create(:user) }

    it "links the conversation to the user" do
      conversation.link_to_user!(user)
      expect(conversation.reload.user).to eq(user)
    end
  end
end
```

### Ejemplo: User con Google OAuth

```ruby
# spec/models/user_spec.rb
RSpec.describe User do
  describe "#google_connected?" do
    context "when google_refresh_token is present" do
      let(:user) { build(:user, :with_google_oauth) }
      it { expect(user.google_connected?).to be true }
    end

    context "when google_refresh_token is nil" do
      let(:user) { build(:user, google_refresh_token: nil) }
      it { expect(user.google_connected?).to be false }
    end
  end
end
```

### Ejemplo: Gateway

```ruby
# spec/gateways/google/calendar/list_events_gateway_spec.rb
RSpec.describe Gateways::Google::Calendar::ListEventsGateway do
  describe "#perform" do
    subject(:result) { described_class.new(access_token: token).perform }

    let(:token) { "valid_access_token" }

    context "when API returns events" do
      before do
        stub_google_calendar_events(events: [
          { id: "1", summary: "Meeting", start: 1.hour.from_now }
        ])
      end

      it { expect(result).to be_success }
      it { expect(result.data).to be_an(Array) }
      it { expect(result.data.first[:summary]).to eq("Meeting") }
    end

    context "when API returns error" do
      before do
        stub_google_calendar_error(status: 401, message: "Invalid token")
      end

      it { expect(result).to be_failure }
      it { expect(result.error).to include("Invalid token") }
    end
  end
end
```

### Ejemplo: Interactor Step

```ruby
# spec/interactors/tools/calendar/list_events/validate_user_spec.rb
RSpec.describe Tools::Calendar::ListEvents::ValidateUser do
  describe ".call" do
    subject(:result) { described_class.call(conversation: conversation) }

    context "when user is connected to Google" do
      let(:user) { create(:user, :with_google_oauth) }
      let(:conversation) { create(:conversation, user: user) }

      it { expect(result).to be_success }
      it { expect(result.user).to eq(user) }
    end

    context "when user is not connected to Google" do
      let(:user) { create(:user) }
      let(:conversation) { create(:conversation, user: user) }

      it { expect(result).to be_failure }
      it { expect(result.error).to include("no autenticado") }
      it { expect(result.needs_oauth).to be true }
      it { expect(result.oauth_url).to be_present }
    end

    context "when conversation has no user" do
      let(:conversation) { create(:conversation, user: nil) }

      it { expect(result).to be_failure }
      it { expect(result.needs_oauth).to be true }
    end
  end
end
```

---

## 4. Tests de Integración

Tests que verifican la interacción entre múltiples componentes.

### ¿Qué testear como integración?

| Tipo | Qué testear |
|------|-------------|
| **Interactors completos** | Flujo end-to-end del organizer |
| **Tools endpoints** | HTTP request → response (mockeando Google APIs) |
| **OAuth callbacks** | Flujo completo de OAuth |

### Ejemplo: Interactor Completo

```ruby
# spec/interactors/tools/calendar/list_events_interactor_spec.rb
RSpec.describe Tools::Calendar::ListEventsInteractor do
  describe ".call" do
    subject(:result) { described_class.call(conversation: conversation) }

    let(:user) { create(:user, :with_google_oauth) }
    let(:conversation) { create(:conversation, user: user) }

    before do
      # Mock Google Calendar API
      stub_google_calendar_events(events: [
        { id: "1", summary: "Meeting", start: 1.hour.from_now },
        { id: "2", summary: "Lunch", start: 3.hours.from_now }
      ])
    end

    it { expect(result).to be_success }
    it { expect(result.events.count).to eq(2) }
    it { expect(result.events.first[:summary]).to eq("Meeting") }
  end
end
```

---

## 5. Tests de Sistema

Tests end-to-end que simulan flujos completos.

### ¿Qué testear como sistema?

| Flujo | Descripción |
|-------|-------------|
| **OAuth Flow** | Usuario conecta su cuenta de Google |

### Ejemplo: OAuth Flow

```ruby
# spec/system/oauth/google_oauth_flow_spec.rb
RSpec.describe "Google OAuth Flow", type: :system do
  let(:conversation) { create(:conversation, user: nil) }

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: "123456",
      info: { email: "user@example.com", name: "Test User" },
      credentials: {
        token: "access_token",
        refresh_token: "refresh_token",
        expires_at: 1.hour.from_now.to_i
      }
    })
  end

  it "creates user and links to conversation" do
    visit oauth_google_path(conversation_id: conversation.id)

    expect(User.count).to eq(1)
    expect(conversation.reload.user).to be_present
    expect(conversation.user.email_address).to eq("user@example.com")
    expect(conversation.user.google_refresh_token).to be_present
  end
end
```

---

## 6. Testing de Tools

Los Tools son endpoints HTTP que ElevenLabs consume. Se testean como **request specs**.

### Shared Examples para Tools

```ruby
# spec/support/shared_examples/tool_examples.rb
RSpec.shared_examples "a tool endpoint" do
  context "without service token" do
    before { request_headers.delete("Authorization") }

    it "returns 401 unauthorized" do
      make_request
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with invalid service token" do
    before { request_headers["Authorization"] = "Bearer invalid_token" }

    it "returns 401 unauthorized" do
      make_request
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with non-existent conversation" do
    before { params[:conversation_id] = "invalid_id" }

    it "returns 404 not found" do
      make_request
      expect(response).to have_http_status(:not_found)
    end
  end
end
```

### Ejemplo: Calendar Tool Spec

```ruby
# spec/requests/api/tools/calendar_spec.rb
RSpec.describe "Api::Tools::Calendar", type: :request do
  let(:user) { create(:user, :with_google_oauth) }
  let(:conversation) { create(:conversation, user: user) }
  let(:service_token) { ENV.fetch("ELEVENLABS_SERVICE_TOKEN", "test_token") }
  
  let(:request_headers) do
    {
      "Authorization" => "Bearer #{service_token}",
      "Content-Type" => "application/json"
    }
  end
  
  let(:params) { { conversation_id: conversation.external_chat_id } }

  describe "GET /api/tools/calendar" do
    subject(:make_request) do
      get "/api/tools/calendar", params: params, headers: request_headers
    end

    it_behaves_like "a tool endpoint"

    context "when user is connected to Google" do
      before do
        stub_google_calendar_events(events: [
          { id: "1", summary: "Meeting", start: 1.hour.from_now }
        ])
      end

      it "returns events" do
        make_request
        
        expect(response).to have_http_status(:ok)
        expect(json_response["events"]).to be_present
        expect(json_response["events"].first["summary"]).to eq("Meeting")
      end
    end

    context "when user is not connected to Google" do
      let(:user) { create(:user) } # Sin OAuth

      it "returns error with oauth_url" do
        make_request
        
        expect(response).to have_http_status(:unauthorized)
        expect(json_response["error"]).to include("autenticado")
        expect(json_response["needs_oauth"]).to be true
        expect(json_response["oauth_url"]).to be_present
      end
    end

    context "when Google API returns error" do
      before do
        stub_google_calendar_error(status: 500, message: "Internal error")
      end

      it "returns error" do
        make_request
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["error"]).to be_present
      end
    end
  end

  describe "POST /api/tools/calendar" do
    subject(:make_request) do
      post "/api/tools/calendar", params: params.to_json, headers: request_headers
    end

    let(:params) do
      {
        conversation_id: conversation.external_chat_id,
        summary: "New Meeting",
        start_time: 1.day.from_now.iso8601,
        end_time: (1.day.from_now + 1.hour).iso8601
      }
    end

    before do
      stub_google_calendar_create_event(event_id: "new_event_123")
    end

    it "creates event and returns it" do
      make_request
      
      expect(response).to have_http_status(:created)
      expect(json_response["event"]["id"]).to eq("new_event_123")
    end
  end
end
```

---

## 7. Mocking de Google APIs

### Stubs Helper

```ruby
# spec/support/google_api_stubs.rb
module GoogleApiStubs
  def stub_google_calendar_events(events:)
    items = events.map do |event|
      {
        "id" => event[:id],
        "summary" => event[:summary],
        "start" => { "dateTime" => event[:start].iso8601 },
        "end" => { "dateTime" => (event[:end] || event[:start] + 1.hour).iso8601 }
      }
    end

    stub_request(:get, /googleapis.com\/calendar\/v3\/calendars/)
      .to_return(
        status: 200,
        body: { items: items }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_google_calendar_create_event(event_id:)
    stub_request(:post, /googleapis.com\/calendar\/v3\/calendars/)
      .to_return(
        status: 200,
        body: { id: event_id }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_google_calendar_error(status:, message:)
    stub_request(:get, /googleapis.com\/calendar\/v3\/calendars/)
      .to_return(
        status: status,
        body: { error: { message: message } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_google_token_refresh(access_token:)
    stub_request(:post, "https://oauth2.googleapis.com/token")
      .to_return(
        status: 200,
        body: {
          access_token: access_token,
          expires_in: 3600,
          token_type: "Bearer"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end

RSpec.configure do |config|
  config.include GoogleApiStubs
end
```

---

## 8. Factories

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password123" }

    trait :with_google_oauth do
      google_refresh_token { "encrypted_refresh_token" }
      google_token_expires_at { 1.hour.from_now }
    end
  end
end

# spec/factories/conversations.rb
FactoryBot.define do
  factory :conversation do
    sequence(:external_chat_id) { |n| "+549111555#{n.to_s.rjust(4, '0')}" }
    channel { :whatsapp }
    user { nil }

    trait :linked do
      user
    end
  end
end
```

---

## 9. Configuración

### spec/rails_helper.rb

```ruby
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

abort("Running in production!") if Rails.env.production?
require "rspec/rails"

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.fixture_path = Rails.root.join("spec/fixtures")
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include FactoryBot::Syntax::Methods
end
```

### spec/support/request_helpers.rb

```ruby
module RequestHelpers
  def json_response
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
```

### spec/support/webmock.rb

```ruby
require "webmock/rspec"

WebMock.disable_net_connect!(allow_localhost: true)
```

---

## Ejecutar Tests

```bash
# Todos los tests
bundle exec rspec

# Por tipo
bundle exec rspec spec/models/
bundle exec rspec spec/requests/api/tools/
bundle exec rspec spec/gateways/

# Con tags
bundle exec rspec --tag focus

# Con coverage
COVERAGE=true bundle exec rspec
```

---

## Resumen de Tipos de Test

| Tipo | Ubicación | Propósito | Mocking |
|------|-----------|-----------|---------|
| **Unitario** | `spec/models/`, `spec/gateways/` | Testear una unidad aislada | Mock dependencias externas |
| **Integración** | `spec/requests/`, `spec/interactors/` | Testear flujos entre componentes | Mock Google APIs |
| **Sistema** | `spec/system/` | Testear flujos E2E | Mock OAuth provider |

---

## Notas Importantes

> [!IMPORTANT]
> Siempre mockear Google APIs con WebMock para evitar llamadas reales en tests.

> [!TIP]
> Usar shared examples para validar autenticación de Tools (service token).

> [!WARNING]
> Setear `ELEVENLABS_SERVICE_TOKEN` en el entorno de test o usar valor por defecto.
