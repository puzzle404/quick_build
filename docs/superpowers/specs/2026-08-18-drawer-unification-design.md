# Unificación de modales en un panel lateral derecho (drawer)

Fecha: 2026-08-18
Estado: aprobado (sección 1 confirmada por el usuario; secciones 2-4 decididas por el asistente con criterio propio, el usuario se desconectó y pidió continuar)

## Contexto

Hoy conviven tres mecanismos para crear/editar entidades en el namespace `Constructors::`:

1. **Modal centrado** (`qb--modal`, 13 usos): nueva/editar etapa, nueva lista de materiales, nota, gasto, invitar miembro, subir plano/documento/foto de etapa, plantillas.
2. **Drawer lateral** (`qb--drawer`, ya existe, 2 usos): detalle de etapa (`stage_detail` frame) y detalle de lista de materiales / documento de biblioteca (reusan el frame `project_modal` pero con chrome de drawer).
3. **Página completa sin overlay** (3 casos): crear/editar proyecto, editar persona (ficha global y por-obra).

El pedido: unificar todo en el patrón drawer, con el nivel de pulido de un producto profesional, siguiendo el sistema de diseño QB OS. Mobile (`*.html+mobile.erb`) queda **fuera de alcance** — ya tiene su propia navegación full-screen con flecha atrás y funciona bien.

## 1. Arquitectura (aprobada)

- **Un solo turbo-frame**, `drawer`, montado una única vez en `layouts/constructor.html.erb`. Reemplaza a `project_modal` y `stage_detail`, que desaparecen como conceptos separados.
- Vivir en el layout (no en cada vista) permite que triggers globales — el botón "+ Nuevo proyecto" del sidebar, alcanzable desde cualquier pantalla — abran el panel sin importar en qué página está el usuario.
- **`Qb::DrawerComponent`** (nuevo, `app/components/qb/`): arma el header fijo (eyebrow + título + subtítulo opcional + cerrar), el cuerpo scrolleable y un footer fijo opcional. Cada vista lo renderiza dentro del frame en vez de reinventar el armazón.
- El Stimulus controller **`qb--drawer`** se mantiene y se mejora (ver §2). **`qb--modal` se elimina** — tras la migración nada lo usa, y mantener dos controllers casi idénticos no aporta nada.
- **Detalle de etapa y edición de etapa comparten el mismo panel**: "Editar" ya no abre una segunda superficie encima; reemplaza el contenido del mismo frame. Es la mejora directa sobre la referencia que dio el usuario.
- Regla de apertura/cierre: **frame vacío ⇒ panel cerrado; frame con contenido ⇒ panel abierto.** Un solo listener (`turbo:frame-load` sobre el frame `drawer`) decide todo; se eliminan los flags booleanos por vista (`data-*-open-on-connect-value`, el chequeo `closest("turbo-frame#project_modal")`, etc.).
- El fallback de página completa (acceso directo por URL / sin JS) se conserva donde ya existe (etapas, listas de materiales) y **se agrega** donde falta (proyecto, persona) — no se quita capacidad, solo se suma la rama de panel.

## 2. Diseño visual e interacción (decisiones del asistente)

- **Header** (fijo, no scrollea): eyebrow mono en mayúsculas con el contexto (ej. "PRJ-001 · Planificación"), título de la entidad/acción, línea de subtítulo opcional (pills de estado, meta), botón cerrar (X) a la derecha. El título deja de vivir "adentro" del contenido scrolleable (como hoy en el detalle de etapa) y pasa al header — se ve siempre, incluso con scroll.
- **Cuerpo**: `flex:1; overflow:auto`, padding estándar 18-20px.
- **Footer** (fijo, no scrollea, `border-top`): para formularios, Cancelar (secondary) + acción primaria, alineados a la derecha — dejan de estar sueltos dentro del form como hoy. Para vistas de solo lectura (detalle de etapa), acciones contextuales (Editar como primaria, resto en el menú kebab `Qb::MenuComponent` ya existente de la tarea de botonera).
- **Anchos**: dos tamaños, no una escala arbitraria por vista — `:md` (480px, formularios cortos: nota, gasto, invitar miembro) y `:lg` (560px, formularios con más campos o contenido rico: etapa, lista de materiales, proyecto, detalle de etapa).
- **Backdrop**: `rgba(0,0,0,.4)`, click afuera del panel cierra (comportamiento ya existente, se conserva).
- **Animación**: panel entra con `translateX(100% → 0)` + backdrop con fade de opacidad, ~180ms ease-out; reversa al cerrar. Respeta `prefers-reduced-motion` (sin transform, solo fade). Hoy no existe ninguna animación (toggle de `display`); es la mejora de percepción más visible del pedido "más profesional".
- **Estado de carga**: mientras el frame busca contenido nuevo (`turbo-frame[busy]`), el contenido anterior se atenúa a opacidad ~0.5 y se desactivan los clicks — señal barata, sin spinner ni JS nuevo.
- **Foco**: al abrir, el foco se mueve al panel; Escape cierra (ya existe). **No se implementa un focus-trap completo** — es una herramienta interna, el costo/riesgo de un trap robusto no se justifica todavía; queda anotado como corte de alcance deliberado, no como olvido.
- **Navegación cruzada de página**: cerrar + parchear en el lugar cubre 17 de los 18 casos (todos editan algo que ya se está mirando). La única excepción real es **crear proyecto** desde el botón global: el usuario espera terminar en la página del proyecto nuevo, no en la que tenía abierta. Para ese caso puntual se agrega una Turbo Stream action custom (`redirect`, patrón documentado de Turbo/Hotwire) que hace un `Turbo.visit` real; el resto de los formularios no la necesita.
- El atajo **⌘N** deja de hacer `Turbo.visit` de página completa (decisión previa, documentada en un comentario que esta migración reemplaza a propósito) y pasa a abrir el drawer, coherente con el resto.

## 3. Inventario de migración

**De modal centrado a drawer (13):**
`header_component` (kebab editar/eliminar ya usa link_to, no un form — revisar si sigue necesitando `qb--modal` o pasa a link directo), `members_panel_component` (invitar miembro), `stage_detail_component` (el propio host del drawer de etapa — se simplifica), `expenses/index` (nuevo gasto), `blueprints/new`, `material_lists/{new,edit}`, `projects/people/new`, `projects/show` (host del drawer), `stages/documents/new`, `stages/edit`, `stages/images/new`, `stages/new`.

**Ya drawer, se re-skinean con el componente nuevo (2):** `library/show`, `projects/material_lists/show`.

**De página completa a drawer + fallback (3):** `projects/new`, `projects/edit`, `people/edit` (global y por-obra — 2 vistas).

**Se elimina:** `qb--modal` controller. **Se renombra:** frame `project_modal` y `stage_detail` → `drawer`.

## 4. Verificación

- Specs de request por formulario convertido: `turbo_frame_request?` devuelve el panel; request normal devuelve el fallback de página completa.
- Un system spec (JS) que verifique la transición "ver detalle → editar" dentro del mismo frame, sin que el panel se cierre entre medio.
- Suite completa + rubocop + el barrido de rutas (desktop/mobile) que se usó el resto de la sesión, para confirmar cero regresiones en las 18 pantallas migradas y en todo lo que ya funcionaba.

## Auto-revisión

- Sin placeholders ni TBD.
- Alcance acotado: 18 call sites + 1 componente + 1 controller + 1 frame en el layout — es un solo proyecto, no requiere descomponerse más.
- Ambigüedad resuelta explícitamente donde apareció (navegación cruzada de página, focus-trap, ⌘N).
