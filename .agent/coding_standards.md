# SaraAI - Coding Standards

Este documento describe las convenciones y patrones de código para la aplicación SaraAI.

> [!NOTE]
> **Recordar**: Rails solo expone **Tools** (endpoints HTTP) que ElevenLabs consume. 
> No llamamos a OpenAI ni ElevenLabs desde Rails.

---

## Tabla de Contenidos

1. [Interactors](#1-interactors)
2. [Services](#2-services)
3. [Gateways](#3-gateways)
4. [Controllers](#4-controllers)
5. [Tools Controllers](#5-tools-controllers)
6. [Components (ViewComponent)](#6-components-viewcomponent)
7. [Jobs](#7-jobs)
8. [Mailers](#8-mailers)
9. [Models](#9-models)
10. [Queries](#10-queries)
11. [Concerns](#11-concerns)
12. [Linter & Formatter](#12-linter--formatter)
13. [Git Commits](#13-git-commits)

---

## 1. Interactors

Los interactors encapsulan la lógica de negocio en operaciones atómicas. Utilizan la gema `interactor`.

### Estructura de Archivos

```
app/interactors/
├── tools/
│   ├── calendar/
│   │   ├── list_events_interactor.rb
│   │   └── list_events/
│   │       ├── validate_user.rb
│   │       ├── fetch_events.rb
│   │       └── format_response.rb
│   └── gmail/
│       └── search_emails_interactor.rb
└── oauth/
    └── complete_google_auth_interactor.rb
```

### Convenciones

- **Nomenclatura**: `{Nombre}Interactor` para organizers, `{Nombre}::{Step}` para steps
- **Argumentos**: Usar `required_arguments` y `optional_arguments`
- **Errores**: Usar `context.fail!(error: "mensaje")`
- **Delegación**: Usar `delegate` para acceder a valores del context

### Ejemplo: Organizer

```ruby
class Tools::Calendar::ListEventsInteractor
  include Interactor::Organizer

  required_arguments [:conversation]
  optional_arguments [:date_from, :date_to]

  organize Tools::Calendar::ListEvents::ValidateUser,
    Tools::Calendar::ListEvents::FetchEvents,
    Tools::Calendar::ListEvents::FormatResponse
end
```

### Ejemplo: Step

```ruby
class Tools::Calendar::ListEvents::ValidateUser
  include Interactor

  delegate :conversation, to: :context

  def call
    set_user
    validate_google_connection
  end

  private

  def set_user
    context.user = conversation.user
  end

  def validate_google_connection
    return if context.user&.google_connected?
    fail_with_oauth_required
  end

  def fail_with_oauth_required
    context.fail!(
      error: "Usuario no autenticado con Google",
      needs_oauth: true,
      oauth_url: generate_oauth_url
    )
  end

  def generate_oauth_url
    Rails.application.routes.url_helpers.oauth_google_path(
      conversation_id: conversation.id
    )
  end
end
```

### Invocación

```ruby
result = Tools::Calendar::ListEventsInteractor.call(
  conversation: conversation,
  date_from: Date.today,
  date_to: Date.today + 7.days
)

if result.success?
  render json: { events: result.events }
else
  render json: { error: result.error, oauth_url: result.oauth_url }, status: :unauthorized
end
```

---

## 2. Services

Los services encapsulan lógica que no requiere el patrón interactor (operaciones más simples).

### Estructura de Archivos

```
app/services/
├── base_service.rb
├── oauth/
│   └── google_token_refresh_service.rb
└── conversations/
    └── link_user_service.rb
```

### Convenciones

- **Nomenclatura**: `{Nombre}Service` o namespace anidado
- **Método de clase**: `self.perform` que instancia y ejecuta
- **Método principal**: `perform` (instancia)

### Ejemplo

```ruby
class Oauth::GoogleTokenRefreshService
  attr_reader :user

  def self.perform(user:)
    new(user:).perform
  end

  def initialize(user:)
    @user = user
  end

  def perform
    return unless has_refresh_token?
    refresh_token_on_google
    extract_access_token
  end

  private

  def has_refresh_token?
    user.google_refresh_token.present?
  end

  def refresh_token_on_google
    @response = Gateways::Google::RefreshTokenGateway.new(
      refresh_token: user.google_refresh_token
    ).perform
  end

  def extract_access_token
    @response.success? ? @response.access_token : nil
  end
end
```

### Invocación

```ruby
access_token = Oauth::GoogleTokenRefreshService.perform(user: user)
```

---

## 3. Gateways

Los gateways manejan la comunicación con servicios externos (Google APIs).

### Estructura de Archivos

```
app/gateways/
├── google/
│   ├── base_gateway.rb
│   ├── refresh_token_gateway.rb
│   ├── calendar/
│   │   ├── list_events_gateway.rb
│   │   └── create_event_gateway.rb
│   └── gmail/
│       ├── search_gateway.rb
│       └── read_message_gateway.rb
└── result.rb
```

### Convenciones

- **Nomenclatura**: `Gateways::{Proveedor}::{Acción}Gateway`
- **Método principal**: `perform`
- **Manejo de errores**: Capturar excepciones y retornar Result object
- **Herencia**: Heredar de `BaseGateway` para lógica común

### Ejemplo: Base Gateway

```ruby
# app/gateways/google/base_gateway.rb
class Gateways::Google::BaseGateway
  attr_reader :access_token

  def initialize(access_token:)
    @access_token = access_token
  end

  private

  def connection
    @connection ||= Faraday.new do |f|
      f.request :json
      f.response :json
      f.headers["Authorization"] = "Bearer #{access_token}"
    end
  end

  def success(data)
    Gateways::Result.new(success: true, data: data)
  end

  def failure(error)
    Gateways::Result.new(success: false, error: error)
  end
end
```

### Ejemplo: Gateway Específico

```ruby
# app/gateways/google/calendar/list_events_gateway.rb
class Gateways::Google::Calendar::ListEventsGateway < BaseGateway
  CALENDAR_API = "https://www.googleapis.com/calendar/v3".freeze

  def initialize(access_token:, date_from: nil, date_to: nil)
    super(access_token: access_token)
    @date_from = date_from || Time.current
    @date_to = date_to || 7.days.from_now
  end

  def perform
    fetch_events_from_google
    build_result
  rescue Faraday::Error => e
    failure(e.message)
  end

  private

  def fetch_events_from_google
    @response = connection.get("#{CALENDAR_API}/calendars/primary/events", params)
  end

  def build_result
    return failure(parse_error_message) unless @response.success?
    success(parse_events(@response.body))
  end

  def parse_error_message
    @response.body["error"]["message"]
  end

  def params
    {
      timeMin: @date_from.iso8601,
      timeMax: @date_to.iso8601,
      singleEvents: true,
      orderBy: "startTime"
    }
  end

  def parse_events(body)
    (body["items"] || []).map do |event|
      {
        id: event["id"],
        summary: event["summary"],
        start: event.dig("start", "dateTime") || event.dig("start", "date"),
        end: event.dig("end", "dateTime") || event.dig("end", "date")
      }
    end
  end
end
```

### Result Object

```ruby
# app/gateways/result.rb
class Gateways::Result
  attr_reader :data, :error

  def initialize(success:, data: nil, error: nil)
    @success = success
    @data = data
    @error = error
  end

  def success? = @success
  def failure? = !@success
end
```

---

## 4. Controllers

### Estructura de Archivos

```
app/controllers/
├── application_controller.rb
├── home_controller.rb
├── sessions_controller.rb
├── oauth/
│   └── google_controller.rb
└── concerns/
    └── authenticatable.rb
```

### Convenciones

- **Herencia**: Controllers heredan de `ApplicationController`
- **Concerns**: Usar `include` para funcionalidad compartida
- **Solo orquestación**: Delegar lógica a interactors/services

### Ejemplo: OAuth Controller

```ruby
class Oauth::GoogleController < ApplicationController
  def new
    redirect_to google_oauth_url, allow_other_host: true
  end

  def callback
    complete_oauth
    handle_result
  end

  private

  def complete_oauth
    @result = Oauth::CompleteGoogleAuthInteractor.call(
      auth: request.env["omniauth.auth"],
      conversation_id: params[:state]
    )
  end

  def handle_result
    return redirect_to(success_path, notice: "Cuenta conectada") if @result.success?
    redirect_to error_path, alert: @result.error
  end

  def google_oauth_url
    "/auth/google_oauth2?state=#{params[:conversation_id]}"
  end
end
```

---

## 5. Tools Controllers

Controllers especiales que exponen endpoints para ElevenLabs.

### Estructura

```
app/controllers/api/tools/
├── base_controller.rb
├── auth_controller.rb
├── calendar_controller.rb
└── gmail_controller.rb
```

### Base Controller

```ruby
# app/controllers/api/tools/base_controller.rb
class Api::Tools::BaseController < ActionController::API
  before_action :authenticate_service!
  before_action :set_conversation

  private

  def authenticate_service!
    token = request.headers["Authorization"]&.gsub("Bearer ", "")

    unless token == ENV.fetch("ELEVENLABS_SERVICE_TOKEN")
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def set_conversation
    @conversation = Conversation.find_by!(
      external_chat_id: params[:conversation_id]
    )
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Conversation not found" }, status: :not_found
  end
end
```

### Ejemplo: Calendar Tools

```ruby
# app/controllers/api/tools/calendar_controller.rb
class Api::Tools::CalendarController < BaseController
  # GET /api/tools/calendar/events
  def index
    list_events
    render_events_response
  end

  # POST /api/tools/calendar/events
  def create
    create_event
    render_create_response
  end

  private

  def list_events
    @result = ::Tools::Calendar::ListEventsInteractor.call(
      conversation: @conversation,
      date_from: params[:date_from],
      date_to: params[:date_to]
    )
  end

  def render_events_response
    return render(json: { events: @result.events }) if @result.success?
    render json: { error: @result.error, needs_oauth: @result.needs_oauth, oauth_url: @result.oauth_url },
           status: @result.needs_oauth ? :unauthorized : :unprocessable_entity
  end

  def create_event
    @result = ::Tools::Calendar::CreateEventInteractor.call(
      conversation: @conversation,
      summary: params[:summary],
      start_time: params[:start_time],
      end_time: params[:end_time]
    )
  end

  def render_create_response
    return render(json: { event: @result.event }, status: :created) if @result.success?
    render json: { error: @result.error }, status: :unprocessable_entity
  end
end
```

### Rutas para Tools

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :tools do
      resource :auth, only: [], controller: :auth do
        get :oauth_link
        get :status
      end
      
      resources :calendar, only: [:index, :create], controller: :calendar
      
      resources :gmail, only: [:index, :show], controller: :gmail do
        collection do
          get :search
        end
      end
    end
  end
end
```

---

## 6. Components (ViewComponent)

> [!NOTE]
> En este proyecto usamos **ERB** para los templates, no HAML.

### Estructura de Archivos

```
app/components/
├── application_component.rb
└── shared/
    ├── alert_component.rb
    └── alert_component.html.erb
```

### Ejemplo

```ruby
class Shared::AlertComponent < ViewComponent::Base
  def initialize(type:, message:)
    super()
    @type = type
    @message = message
  end

  def render?
    @message.present?
  end
end
```

### Template (ERB)

```erb
<%# app/components/shared/alert_component.html.erb %>
<div class="alert alert-<%= @type %>" role="alert">
  <%= @message %>
</div>
```

---

## 7. Jobs

Los jobs manejan procesamiento asíncrono.

### Estructura de Archivos

```
app/jobs/
├── application_job.rb
└── oauth/
    └── cleanup_expired_tokens_job.rb
```

### Ejemplo

```ruby
class Oauth::CleanupExpiredTokensJob < ApplicationJob
  queue_as :low_priority

  def perform
    find_expired_tokens
    clear_expired_tokens
  end

  private

  def find_expired_tokens
    @expired_users = User.where("google_token_expires_at < ?", 30.days.ago)
  end

  def clear_expired_tokens
    @expired_users.update_all(google_refresh_token: nil)
  end
end
```

---

## 8. Mailers

### Ejemplo

```ruby
class NotificationMailer < ApplicationMailer
  def oauth_connected(user:)
    @user = user
    mail(to: @user.email, subject: "Cuenta de Google conectada ✅")
  end
end
```

---

## 9. Models

### Estructura

```
app/models/
├── application_record.rb
├── user.rb
├── session.rb
└── conversation.rb
```

### Ejemplo: Conversation

```ruby
class Conversation < ApplicationRecord
  # Associations
  belongs_to :user, optional: true

  # Validations
  validates :external_chat_id, presence: true, uniqueness: true
  validates :channel, presence: true

  # Enums
  enum :channel, { whatsapp: 0 }

  # Scopes
  scope :linked, -> { where.not(user_id: nil) }
  scope :unlinked, -> { where(user_id: nil) }

  # Instance methods
  def linked?
    user_id.present?
  end

  def link_to_user!(user)
    update!(user: user)
  end
end
```

### Ejemplo: User

```ruby
class User < ApplicationRecord
  has_secure_password

  # Associations
  has_many :sessions, dependent: :destroy
  has_many :conversations, dependent: :nullify

  # Validations
  validates :email_address, presence: true, uniqueness: true

  # Google OAuth
  def google_connected?
    google_refresh_token.present?
  end

  def google_access_token
    Oauth::GoogleTokenRefreshService.perform(user: self)
  end
end
```

---

## 10. Queries

### Ejemplo

```ruby
class ConversationQueries::UnlinkedByChannel
  def initialize(channel:)
    @channel = channel
  end

  def perform
    Conversation.unlinked.where(channel: @channel)
  end
end
```

---

## 11. Concerns

### Model Concern

```ruby
module GoogleOauthable
  extend ActiveSupport::Concern

  included do
    encrypts :google_refresh_token
  end

  def google_connected?
    google_refresh_token.present?
  end

  def disconnect_google!
    revoke_google_tokens
    clear_google_data
  end

  private

  def revoke_google_tokens
    # Llamar a Google para revocar tokens si es necesario
  end

  def clear_google_data
    update!(google_refresh_token: nil, google_token_expires_at: nil)
  end
end
```

### Controller Concern

```ruby
module ToolAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_service!
  end

  private

  def authenticate_service!
    token = request.headers["Authorization"]&.gsub("Bearer ", "")
    head :unauthorized unless valid_service_token?(token)
  end

  def valid_service_token?(token)
    token.present? && ActiveSupport::SecurityUtils.secure_compare(
      token,
      ENV.fetch("ELEVENLABS_SERVICE_TOKEN")
    )
  end
end
```

---

## 12. Linter & Formatter

Usamos **StandardRB** para mantener un estilo consistente.

```bash
# Ejecutar linter
bundle exec standardrb

# Auto-fix
bundle exec standardrb --fix
```

### Configuración

```yaml
# .standard.yml
ruby_version: 3.3
ignore:
  - 'db/schema.rb'
  - 'node_modules/**/*'
  - 'vendor/**/*'
```

---

## 13. Git Commits

Formato: **Conventional Commits**

```
<tipo>(<scope>): <descripción>
```

### Tipos

| Tipo | Descripción |
|------|-------------|
| `feat` | Nueva funcionalidad |
| `fix` | Bug fix |
| `docs` | Documentación |
| `refactor` | Refactorización |
| `test` | Tests |
| `chore` | Mantenimiento |

### Ejemplos

```
feat(tools): add calendar.list_events endpoint
fix(oauth): handle expired refresh tokens
docs(readme): update setup instructions
refactor(gateways): extract base gateway class
```

---

## Gemas Recomendadas

| Gema | Propósito |
|------|-----------|
| `interactor` | Patrón interactor |
| `faraday` | HTTP client |
| `google-apis-calendar_v3` | Google Calendar |
| `google-apis-gmail_v1` | Gmail |
| `view_component` | Componentes de vista |
| `standard` | Linter |
| `rspec-rails` | Testing |
| `factory_bot_rails` | Factories para tests |
| `webmock` | Mock HTTP |

---

## Notas Importantes

> [!IMPORTANT]
> Rails solo expone **Tools** (endpoints HTTP). No llamamos a OpenAI ni ElevenLabs.

> [!TIP]
> Usar Gateways para encapsular llamadas a Google APIs.

> [!WARNING]
> Validar siempre el `ELEVENLABS_SERVICE_TOKEN` en los Tools controllers.

> [!CAUTION]
> Los templates de vistas usan **ERB**, no HAML.
