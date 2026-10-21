# Handoff: Quick Build Mobile — App iOS (Hotwire Native)

## Overview

Diseño completo de la app mobile **Quick Build para iOS**, pensada para usar **Hotwire Native** (el repo `puzzle404/quick_build` ya tiene los hooks `ConfigurationsController#ios_v1`). 22 pantallas que cubren onboarding, tabs principales, gestión de proyectos, planificación, materiales, planos·IA, equipo, documentos, y modales para creación/edición.

El diseño respeta y extiende el sistema de diseño del rediseño web (mismos tokens oklch, tipografía Geist, paleta cobalto + tema Night), adaptado a patrones nativos iOS: large titles, grouped settings forms, bottom-sheet modals, segmented controls, underline tabs, blur en tab bar, safe areas.

---

## About the Design Files

Los archivos en `design_handoff_quick_build_mobile/` son **prototipos React renderizados en HTML** que muestran el diseño visual e interacciones de cada pantalla.

**No son código de producción para copiar directamente.** La estrategia recomendada es:

1. **Hotwire Native shell (Swift):** un app iOS minimal con UINavigationController + UITabBarController + Hotwire Native registrados como path configurations. Toda la lógica de pantalla viene de Rails vía Turbo Frames.
2. **Vistas Rails mobile-first:** crear un namespace `app/views/mobile/` o usar `Hotwire::Native::Navigation` para detectar el cliente y renderizar variantes ERB con el mismo CSS responsive.
3. **Bottom-sheets nativos** (`UISheetPresentationController`) para los modales — el backend devuelve la URL y el shell decide presentarla como modal sheet.

---

## Fidelity

**High-fidelity.** Colores, tipografía, spacing, transiciones, hover/press states e iconografía están definidos. El desarrollador debe reproducir pixel-fidelity ajustando solo a los modismos del stack target (CSS responsive con media queries y `safe-area-inset-*`).

---

## Stack target

- **Rails 8** con ViewComponent ya existentes (`Qb::*`, `Constructors::*`)
- **Hotwire Native iOS** (Swift) — usar el endpoint `ConfigurationsController#ios_v1` existente para path-configuration JSON
- **CSS responsive** con tokens compartidos web/mobile (mismo archivo `app/assets/tailwind/application.css` + `@theme` v4)
- **Turbo Frames** para drawers/sheets, **Turbo Stream** para actualizar listas
- **Stimulus** para tweaks específicos mobile (haptic feedback opcional vía Hotwire Native bridge)

---

## Mapeo a vistas Rails existentes

| Pantalla mobile           | Controlador Rails ya existente                                       | Modelo                |
|--------------------------|----------------------------------------------------------------------|----------------------|
| Welcome / Login / Signup | `SessionsController`, `RegistrationsController`                      | `User`               |
| Dashboard                | `Constructors::DashboardController#index`                            | varios               |
| Proyectos (lista)        | `Constructors::ProjectsController#index`                             | `Project`            |
| Project Overview         | `Constructors::ProjectsController#show`                              | `Project`            |
| Stages (planning)        | `Constructors::Projects::StagesController#index`                     | `ProjectStage`       |
| Stage detail (drawer)    | `Constructors::Projects::StagesController#show`                      | `ProjectStage`       |
| Materials (lists)        | `Constructors::Projects::MaterialListsController#index`              | `MaterialList`       |
| MaterialList detail      | `Constructors::Projects::MaterialListsController#show`               | `MaterialList`+items |
| Blueprints · IA          | `Constructors::Projects::BlueprintsController#index`                 | `Blueprint`          |
| Team                     | `Constructors::Projects::PeopleController#index`                     | `User`+attendance    |
| Documents                | `Constructors::Projects::DocumentsController#index`                  | `Document`           |
| Onboarding nuevo proyecto| `Constructors::ProjectsController#new` (multi-step Turbo)            | `Project`            |
| Modal Gasto              | `Constructors::Projects::ExpensesController#new`                     | `Expense`            |
| Modal Nota               | `Constructors::Projects::NotesController#new`                        | `Note`               |
| Buscar (search)          | `SearchController#index` (crear)                                     | varios (PgSearch)    |
| Library                  | `Constructors::LibraryController#index` (crear)                      | plantillas / proveedores |
| Profile / Settings       | `UsersController#edit`                                               | `User`               |

---

## Design System (idéntico al web)

### Tipografía
- **UI**: Geist (400/500/600/700) — vía Google Fonts
- **Mono**: Geist Mono — para números, códigos, fechas
- Tamaño base mobile: 15px (web es 13px)
- Large titles: 28–32px / 700 / letter-spacing -0.5

### Colores (oklch, mismo Qb token set)

Definidos en `mobile/tokens.css`. Tabla resumida:

| Token              | Light                       | Dark (`[data-theme="night"]`)   |
|--------------------|----------------------------|----------------------------------|
| `--color-bg`       | `oklch(98.5% 0.004 90)`    | `oklch(18% 0.015 250)`           |
| `--color-bg-raised`| `oklch(99.5% 0.003 90)`    | `oklch(22% 0.015 250)`           |
| `--color-bg-sunken`| `oklch(96.5% 0.005 85)`    | `oklch(15% 0.015 250)`           |
| `--color-ink`      | `oklch(18% 0.012 270)`     | `oklch(96% 0.005 250)`           |
| `--color-accent`   | `oklch(55% 0.22 255)` cobalto | `oklch(78% 0.17 75)` amber       |
| `--color-ok`       | `oklch(58% 0.14 155)`      | `oklch(72% 0.15 155)`            |
| `--color-warn`     | `oklch(72% 0.16 75)`       | `oklch(78% 0.17 75)`             |
| `--color-bad`      | `oklch(55% 0.18 25)`       | `oklch(68% 0.19 25)`             |
| `--color-info`     | `oklch(60% 0.13 220)`      | `oklch(72% 0.14 220)`            |

### Radios
- Cards/inputs grandes: 14px
- Botones pill: 999px
- Inputs internos en form groups: 10px
- Bottom sheet: 24px top-left/right

### Patterns clave

- **Underline tabs** (filtros): línea inferior cobalto + chip mono con count. Componente reutilizable `MTabs`. Reemplaza el viejo patrón de pills.
- **iOS grouped forms**: cada modal usa `MFormGroup` (card con título mono uppercase) que contiene `MFormRow` (label uppercase + input `bg-sunken` debajo, o picker estilo settings). Variantes: `MFormToggleRow`, `MFormAmountRow`.
- **Bottom sheet modals**: borde superior redondeado 24px + drag handle 38×5px gris.
- **Tab bar inferior**: 5 tabs (Inicio · Proyectos · Buscar · Biblioteca · Perfil), blur backdrop, safe-area-inset-bottom 24px.
- **Status bar reservado**: 62px de padding-top en cada screen.

---

## 22 Pantallas

Agrupadas en 6 secciones (ver `mobile/app.jsx` para el canvas):

### Autenticación · Onboarding
1. **Welcome** (`mobile/screens-1.jsx#ScreenWelcome`) — splash con valor + CTAs
2. **Login** (`ScreenLogin`)
3. **Sign up** (`ScreenSignup`)

### Tabs principales
4. **Dashboard / Inicio** (`ScreenDashboard`) — 4 KPI hero cards, métricas operativas, proyectos activos, alertas, actividad
5. **Proyectos (lista)** (`ScreenProjects`) — search + tabs underline + cards
6. **Buscar** (`ScreenSearch`) — search global + filter tabs por entidad
7. **Biblioteca** (`ScreenLibrary`) — plantillas, listas reutilizables, proveedores
8. **Perfil / Ajustes** (`ScreenProfile`)

### Proyecto
9. **Project Overview** (`mobile/screens-2.jsx#ScreenProjectOverview`) — hero progress, métricas, section tiles, riesgos, próximas etapas
10. **Stages list** (`ScreenStages`) — cards con sub-etapas expandibles + segmented Cards/Gantt/WBS
11. **Stage detail** (`ScreenStageDetail`) — identidad, métricas, tabs internos (Materiales/Gastos/Notas/Docs/Fotos), bottom action bar
12. **Nueva etapa** modal sheet (`ScreenNewStageModal`)
13. **Plantilla** modal sheet (`ScreenTemplateModal`) — preview de las 3 etapas del `StageTemplateService`

### Materiales
14. **Materials list** (`mobile/screens-3.jsx#ScreenMaterials`) — source chips + filter tabs + cards
15. **Material list detail** (`ScreenMaterialListDetail`) — header + items con qty/unit/total + bottom totals bar
16. **Nueva lista** modal sheet (`ScreenNewMaterialListModal`) — origen Manual/PDF/Excel

### Contenido
17. **Blueprints · IA** (`ScreenBlueprints`) — upload card grande, en curso, completados, en cola
18. **Team** (`ScreenTeam`) — heatmap asistencia + tabs por rol + lista de personas
19. **Documents** (`ScreenDocs`) — tabs por tipo + fijados + recientes

### Creación
20. **Nuevo proyecto · paso 1** (`ScreenNewProject`) — wizard 4 pasos
21. **Modal Gasto** (`ScreenExpenseModal`) — amount input grande + categoría chips
22. **Modal Nota** (`ScreenNoteModal`) — título + contenido + etiquetas + notificar

---

## Componentes reutilizables (mobile/components.jsx)

| Componente       | Propósito                                                     |
|------------------|--------------------------------------------------------------|
| `MIcon`          | Set de 28+ iconos SVG inline, stroke currentColor             |
| `MDot`           | Status dot 8×8 con glow                                       |
| `MPill`          | Status pill 4-radius, 6 tones                                 |
| `MBar`           | Progress bar 4–6px con plan marker opcional                   |
| `MAvatar`        | Monogram avatar con color hash                                |
| `MCard`          | Card raised con border + radius 14                            |
| `MRow`           | iOS-style row con icon + title + subtitle + value + chevron   |
| `MSection`       | Section con título mono uppercase                             |
| `MPageHeader`    | Large title iOS                                               |
| `MNavBar`        | iOS nav bar con back chevron + title centrado                 |
| `MTabBar`        | Bottom tab bar con blur                                       |
| `MButton`        | Primary/secondary/ghost/danger/fill — 3 tamaños               |
| `MKpi`           | Hero card colorida (gradients violet/amber/sky/emerald)       |
| `MSegmented`     | Segmented control iOS                                         |
| `MTabs`          | **Underline tabs** (nuevo design system) con counts           |
| `MFormGroup`     | Grouped settings card con título + footnote                   |
| `MFormRow`       | Form row con label uppercase + input bg-sunken, o picker      |
| `MFormToggleRow` | Switch row iOS-style                                          |
| `MFormAmountRow` | Currency input grande mono                                    |

---

## Tweaks (panel de configuración)

`mobile/tweaks.jsx` expone los mismos tweaks que la web:
- **Tema**: Graphite ↔ Night (atributo `[data-theme="night"]` en cada `.m-screen`)
- **Paleta de acento**: Cobalto, Kiln, Moss, Safety, Ink
- **Densidad**: Compacto / Cómodo / Espacioso (escala font-size)

Estos toggles existen para que el equipo iterare sobre opciones — **no son features de usuario**. En producción, el tema y la paleta deben venir de `User#preferences` (jsonb) sincronizados con la web.

---

## Implementación sugerida — orden

1. **Hotwire Native shell iOS** (Swift)
   - Crear app Xcode con dependencia [hotwire-native-ios](https://github.com/hotwired/hotwire-native-ios)
   - Path configuration desde `/configurations/ios_v1.json` (ya existe el endpoint)
   - `UITabBarController` raíz con 5 tabs (Inicio · Proyectos · Buscar · Biblioteca · Perfil)
   - Cada tab tiene su `Hotwire::Navigator` apuntando a la URL Rails correspondiente
2. **Variant `:mobile` para vistas**
   - Detectar Hotwire Native via header `Hotwire-Native-Visit: 1` o user agent
   - `request.variant = :mobile if hotwire_native?` en `ApplicationController`
   - Crear vistas `*.mobile.erb` para las pantallas con layout distinto del desktop
3. **CSS mobile-first**
   - Mover tokens a `app/assets/tailwind/application.css` con `@theme`
   - Crear archivo `mobile.css` con `.m-screen` + componentes mobile, cargado solo si variant `:mobile`
   - Fuentes Geist + Geist Mono self-hosted
4. **ViewComponents Qb mobile**
   - Implementar los `M*` como ViewComponents bajo `app/components/qb/mobile/`
   - Mismas props que el JSX del prototipo
5. **Pantallas (orden)**
   - Login + Signup (sesión)
   - Tab bar shell + Dashboard
   - Proyectos lista + Project Overview
   - Stages (lista + detail con tabs)
   - Materials (lista + detail con items)
   - Modales (Nueva etapa, Nueva lista, Gasto, Nota, Nuevo proyecto) como Turbo Frame modals con `data-controller="ios-sheet"` que use `UISheetPresentationController`
   - Buscar + Library + Profile
   - Blueprints + Team + Documents
6. **Tweaks producción**
   - Settings de tema/paleta/densidad persistido en `User#preferences`
   - Sincronizado entre web y mobile

---

## Files incluidos

```
design_handoff_quick_build_mobile/
├── README.md                       ← este archivo
├── Quick Build Mobile.html         ← canvas con las 22 pantallas
├── ios-frame.jsx                   ← device frame (status bar, home indicator)
├── design-canvas.jsx               ← canvas pan/zoom
└── mobile/
    ├── tokens.css                  ← tokens oklch + .m-screen
    ├── components.jsx              ← 22 componentes reutilizables (MTabs, MFormRow, etc.)
    ├── tweaks.jsx                  ← panel Tweaks (tema, paleta, densidad)
    ├── screens-1.jsx               ← Welcome, Login, Signup, Dashboard, Proyectos, Buscar, Biblioteca, Perfil
    ├── screens-2.jsx               ← Project Overview, Stages, Stage detail, Nueva etapa, Plantilla
    ├── screens-3.jsx               ← Materials, MaterialList detail, Nueva lista, Blueprints, Team, Docs, Nuevo proyecto, Gasto, Nota
    └── app.jsx                     ← canvas que renderiza todo
```

---

## Notas para Claude Code

- Re-utilizar los ViewComponents existentes (`Qb::ButtonComponent`, `Qb::PillComponent`, etc.) y crear sus versiones mobile bajo `app/components/qb/mobile/`
- Las rutas y controllers ya existen casi todos — solo falta crear `SearchController` y `Constructors::LibraryController`
- Locale `es-AR` para fechas y moneda
- Respetar safe areas iOS: `padding-bottom: env(safe-area-inset-bottom)` en tab bar, `padding-top: env(safe-area-inset-top)` para nav bar
- Touch targets mínimo 44pt (Apple HIG)
- Animaciones de drawers/sheets: usar `UISheetPresentationController` nativo del lado Swift, NO simular con CSS

Cualquier detalle, abrí `Quick Build Mobile.html` en el navegador y mirá el JSX correspondiente — es la fuente de verdad.
