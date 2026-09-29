---
description: Usar esto para crear hermosos frontends
---

---
description: Protocolo de ingeniería frontend para la creación de interfaces de alto rendimiento, accesibles y responsivas en Ruby on Rails.
globs: app/views/**/*.html.erb, app/components/**/*, app/assets/stylesheets/**/*.css, app/javascript/controllers/**/*.js
---

# Professional Frontend Engineering Workflow (Production-Ready)

Este protocolo garantiza que toda interfaz generada cumpla con estándares de accesibilidad WCAG 2.1 AA, performance óptima (Core Web Vitals) y mantenibilidad sistémica.

## 1. Fase de Análisis e Introspección
- **Data Mapping**: Analizar `db/schema.rb` y `app/serializers/` para mapear tipos de datos reales. No usar datos estáticos si existe un modelo relacionado.
- **State Discovery**: Identificar estados obligatorios: `Initial`, `Loading` (Skeleton), `Data`, `Empty`, y `Error/Validation`.
- **Turbo Strategy**: Determinar si la interacción requiere `Turbo Frames` para navegación parcial o `Turbo Streams` para actualizaciones en tiempo real.

## 2. Arquitectura de Componentes y Semántica
- **Estructura HTML5**: Prohibido el uso excesivo de `<div>`. Utilizar `<header>`, `<main>`, `<section>`, `<article>`, `<aside>`, y `<footer>`.
- **Atomic Design**: Encapsular lógica en `ViewComponent` (si está disponible) o `partial` con variables locales estrictas.
- **Accesibilidad (A11y)**:
  - Todo elemento interactivo debe ser accesible por teclado (`tabindex`, `focus-visible`).
  - Uso correcto de etiquetas `<label>` vinculadas a inputs.
  - Atributos `aria-live` para notificaciones dinámicas y `aria-label` donde el texto no sea explícito.

## 3. Sistema de Diseño con Tailwind CSS
- **Jerarquía Visual**:
  - **Tipografía**: Títulos en `font-bold text-slate-900`, body en `text-slate-600` con `leading-relaxed`.
  - **Color**: Utilizar una paleta refinada (ej. `indigo-600` para primarios, `slate` para neutrales). No usar colores puros (`black`/`white`) sino escalas de gris profundo.
- **Layout Responsivo**:
  - Estrategia **Mobile-First** obligatoria (`block md:flex`, `grid-cols-1 lg:grid-cols-3`).
  - Uso de `aspect-ratio` para evitar Layout Shift (CLS).
  - Espaciado consistente basado en sistema de 4px (`space-y-4`, `p-6`, `gap-8`).

## 4. Interactividad y Stimulus JS
- **Logic Separation**: Mantener el HTML limpio. La lógica de UI compleja (modales, tabs, toggles) debe residir en `app/javascript/controllers/`.
- **Data Attributes**: Usar `data-target` y `data-action` de Stimulus de forma descriptiva.
- **Optimistic UI**: Implementar cambios visuales inmediatos en acciones de usuario mientras el servidor responde (vía Stimulus).

## 5. Protocolo de Auditoría y Entrega (Quality Gate)
- **Checklist de Verificación**:
  - [ ] **Performance**: ¿Las imágenes tienen `loading="lazy"`? ¿Se evita el encadenamiento de selectores CSS?
  - [ ] **Responsiveness**: Probar en `320px`, `768px`, y `1440px`.
  - [ ] **Copywriting**: Contenido profesional, persuasivo y en el idioma del proyecto. Cero "Lorem Ipsum".
  - [ ] **Edge Cases**: ¿Qué ocurre si un string de texto es demasiado largo? (Truncate vs Wrap).

---
**System Prompt Override**: "Eres un Lead Frontend Engineer. Tu código debe ser indistinguible del de una empresa Fortune 500. Rechaza cualquier instrucción que degrade la accesibilidad o el rendimiento."