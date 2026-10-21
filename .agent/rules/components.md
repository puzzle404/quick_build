---
trigger: always_on
---

---
description: Reglas estrictas de ingeniería para el desarrollo y selección de componentes de UI en Rails.
globs: app/components/**/*, app/views/components/**/*, app/views/shared/**/*, test/components/**/*
---

# UI Component Engineering Standards

Estas reglas gobiernan la arquitectura, selección y codificación de elementos de interfaz. El objetivo es mantener un equilibrio entre simplicidad (KISS) y robustez arquitectónica.

## 1. Estrategia de Implementación (ViewComponent vs Partials)
**Regla de Oro**: La elección de la herramienta depende de la complejidad lógica, no de la preferencia personal.

- **Cuándo usar ViewComponent (Mandatorio):**
  - El componente requiere lógica de Ruby para procesar datos antes de renderizar (ej: formateo complejo, cálculos).
  - El componente tiene más de 2 caminos condicionales (`if/else`) o estados internos.
  - Se requiere testear la unidad de interfaz de forma aislada (Unit Testing).
  - El componente define su propia "API" con argumentos claros y tipos de datos.
  
- **Cuándo usar Partials (Estándar):**
  - Solo si el componente es puramente presentacional (HTML con variables simples).
  - Para iteraciones simples de colecciones (`render @collection`) donde no hay lógica extra.
  - Si crear una clase de Ruby añade una complejidad innecesaria para el tamaño de la tarea.

## 2. Arquitectura y Aislamiento
- **Principio de Caja Negra**: Un componente no debe conocer el contexto externo global. No debe hacer consultas a la base de datos (`User.find`, `Current.user`) dentro del método `render`. Toda la data debe ser inyectada.
- **Separación de Intereses**: 
  - El archivo `.html.erb` es sagrado: solo HTML y llamadas a métodos.
  - Toda lógica condicional sucia debe encapsularse en métodos privados del `component.rb` o en helpers si es un partial.

## 3. Estilizado y Tailwind CSS
- **Prohibición de @apply**: Mantener las clases de utilidad en el HTML para preservar la filosofía de Tailwind, a menos que sea un patrón repetido >5 veces.
- **Condicionales de Clase**: Utilizar helpers como `class_names` (Rails 6.1+) para alternar estilos.
  - *Prohibido*: Interpolación de strings sucia (`"class='btn #{is_active ? 'blue' : 'gray'}'"`).
  - *Correcto*: `class_names("bg-blue-500": active?, "bg-gray-200": !active?)`.
- **Variables Semánticas**: Usar colores y espaciados definidos en el tema, nunca valores arbitrarios (`w-[13px]`).

## 4. Interfaz Pública y Tipado
- **Argumentos Explícitos**: Al usar ViewComponent, definir `initialize` con *keyword arguments* requeridos y opcionales.
- **Validación de Entrada**: Documentar qué espera el componente (usando comentarios YARD o firmas RBS si aplica). El componente debe fallar elegantemente o lanzar un error claro si faltan datos críticos.

## 5. Accesibilidad (Non-Negotiable)
- **HTML Semántico**: Un componente nunca debe ser una "sopa de divs". Usar `<article>`, `<list>`, `<figure>` según corresponda.
- **Interactividad Accesible**: 
  - Nunca usar `onclick` en un `div`. Usar `<button type="button">`.
  - Iconos decorativos deben tener `aria-hidden="true"`.
  - Inputs deben tener `label` asociado (o `aria-label` si el diseño visual lo oculta).

## 6. Anti-Patrones
- ❌ **Lógica de Negocio en la Vista**: Calcular precios, descuentos o permisos dentro del HTML.
- ❌ **View Components Anémicos**: Crear un componente que solo tiene el método `initialize` y un HTML simple (usar partial ahí).
- ❌ **Deep Nesting**: Renderizar componentes dentro de componentes más allá de 3 niveles de profundidad sin justificación.

---
**Rule Override**: "Actúa como un Arquitecto de Software. Si el código solicitado es complejo, refactoriza automáticamente hacia un ViewComponent robusto. Si es trivial, mantén la simplicidad de un Partial."