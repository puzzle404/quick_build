# Regla: Lógica como Pasos Legibles

> [!CAUTION]
> **Alcance**: Esta regla aplica a **TODO** lugar donde se encapsule lógica que pueda escribirse en pasos: Services, Interactors, Tools, Gateways, Jobs, y cualquier clase con lógica de negocio.

---

## Filosofía Principal

La lógica de negocio debe leerse como una **receta de cocina**: cada paso claramente definido, en orden, con un propósito único.

El método principal (`perform` / `call`) debe actuar como un **índice de contenidos** que describe **QUÉ** se hace, mientras que los métodos privados definen **CÓMO** se hace.

> [!TIP]
> **La regla en una frase**: El método principal solo lista pasos. Cada paso hace UNA sola cosa. Los nombres describen exactamente lo que hacen.

---

## Estructura Universal

```ruby
class [Namespace]::[Nombre]
  def perform  # o call, execute, etc.
    paso_uno
    paso_dos
    paso_tres
  end

  private

  def paso_uno
    # implementación específica
  end
end
```

---

## Ejemplos por Tipo de Clase

### Service

```ruby
def perform
  revoke_token_on_google
  destroy_google_connection
  unlink_conversations
  notify_user
end
```

### Tool (fast-mcp)

```ruby
def call(conversation_id:, summary:, start_time:, end_time:)
  find_conversation
  validate_google_connection
  create_event_on_google
  build_response
end
```

### Gateway

```ruby
def perform
  build_event_payload
  send_request_to_google
  parse_response
end
```

### Job

```ruby
def perform
  find_expired_requests
  log_cleanup_count
  destroy_expired_requests
end
```

---

## Patrones de Nomenclatura

| Prefijo | Uso |
|---------|-----|
| `find_` | Buscar registros |
| `validate_` | Validar condiciones |
| `build_` | Construir objetos/payloads |
| `create_` | Crear registros |
| `update_` | Actualizar registros |
| `destroy_` | Eliminar registros |
| `send_` | Enviar requests/emails |
| `notify_` | Notificar usuarios |
| `parse_` | Parsear respuestas |
| `calculate_` | Realizar cálculos |

### Orden Recomendado

1. **find/set** - Buscar o preparar datos
2. **validate** - Validar condiciones
3. **build** - Construir payloads
4. **process/send** - Ejecutar operación principal
5. **create/update** - Persistir cambios
6. **notify/log** - Notificaciones al final

---

## Anti-Patrones

### ❌ MAL: Lógica mezclada

```ruby
def perform
  if user.google_connection && !user.google_connection.expired?
    response = Faraday.post("...")
    if response.success?
      user.update!(last_sync: Time.current)
    end
  end
end
```

### ✅ BIEN: Pasos claros

```ruby
def perform
  return unless user_has_valid_connection?
  sync_with_google
  update_last_sync
  notify_user
end
```

---

## Checklist Rápido

- [ ] ¿El método principal solo lista pasos?
- [ ] ¿Cada paso tiene nombre descriptivo?
- [ ] ¿Cada método privado hace UNA sola cosa?
- [ ] ¿Los nombres empiezan con verbos?

> [!IMPORTANT]
> **Objetivo**: Cualquier persona que lea el método principal debe entender qué hace la clase sin leer la implementación de cada paso.
