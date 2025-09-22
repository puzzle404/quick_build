# Resumen
Quick Build es una plataforma Rails multi-tenant que conecta a constructores, compradores, vendedores y administradores alrededor de la compra de materiales de construcción. La autenticación y el registro se apoyan en Devise y deben mantenerse compatibles. Cada usuario pertenece a un rol principal y, en el caso de los vendedores, sus cuentas siempre están ligadas a una empresa. El sistema ya admite múltiples empresas, cada una con varios representantes.

> **Enfoque actual**: la primera versión funciona como un centro de gestión de proyectos y control de costos para constructores. Los flujos de marketplace para compradores y vendedores permanecen en la hoja de ruta y no deben bloquear el trabajo centrado en constructores.

## Sistema Operativo del Constructor (MVP)
La persona constructora gestiona la ejecución de obras de punta a punta dentro de la plataforma. Las capacidades clave incluyen:

- **Configuración de obras**: crear nuevos proyectos, nombrarlos, asignar su ubicación y seguir el estado general de las obras activas.
- **Documentación y evidencias**: subir planos en PDF/DWG, adjuntar fotos tomadas en obra y conservar los planos junto al contexto del proyecto.
- **Seguimiento de costos**: visualizar y filtrar gastos por fecha de compra, monto, proveedor, etc.; registrar manualmente gastos realizados fuera de la plataforma o en efectivo; soportar pagos ejecutados dentro de la plataforma cuando estén disponibles.
- **Colaboración**: designar a otro usuario como administrador del proyecto, compartir listados curados de materiales con compañeros o socios y mantener a todos alineados con el alcance.
- **Planificación y control**: mantener una estructura de desglose del trabajo (WBS), asignar responsables, definir hitos y visualizar el progreso mediante diagramas de Gantt y una curva S que compare avance físico vs. plan.
- **Gestión de inventarios**: monitorear stock entre obras, depósitos y acopios para que la disponibilidad de materiales retroalimente la planificación.

## Interfaces en Alcance
- Los constructores trabajan desde un tablero/layout dedicado (ver `app/views/layouts/constructor.html.erb`).
- La gestión de proyectos y membresías vive bajo `app/controllers/constructors/` y está resguardada por políticas en `app/policies/`.
- Helpers como `RolesHelper` y `ApplicationHelper` exponen verificaciones de roles consumidas por componentes de navegación (`app/components/layout/navbar_component*`).

## Expansión de Marketplace y Servicios (Hoja de Ruta)
Las próximas iteraciones retoman la visión más amplia del marketplace:

- Buscar y comparar precios de materiales por marca, características, proveedor, fabricante o cercanía.
- Descubrir profesionales y proveedores de servicios por rubro, calificación y distancia a la obra.
- Solicitar presupuestos de servicios o mano de obra y colaborar con proveedores mediante chat en tiempo real.
- Ofrecer asistencia IA para responder dudas sobre materiales, cantidades y estrategias de compra.
- Ampliar la gestión de perfiles para que constructores y aliados configuren su presencia en la plataforma.

Estas capacidades deben diseñarse sin afectar el modelo de autenticación basado en Devise ni el aislamiento de datos multiempresa existente.

## Tips a tener en cuenta, usar la siguientes herramientas cuando:

- Decorators → cuando tenés lógica de presentación que no pertenece ni al modelo ni a la vista.
Ejemplo: formatear una fecha, mostrar un estado con un label, armar un string complejo para mostrar en la UI. Lógica de presentación por modelo.
- Helpers → Cuando tenés pequeños métodos que se usan en varias vistas, pero no ameritan un decorator o un componente. Útiles para cosas simples: truncar texto, formatear moneda, elegir un ícono según un estado. Métodos chicos y transversales a las vistas.
- Services → Cuando tenés lógica de negocio o procesos largos que no entran en un modelo o controlador.
Ejemplo: cobrar una cuota, sincronizar con una API externa, enviar un reporte. Lógica de negocio puntual y aislada.
- Interactors → Parecidos a los Services, pero pensados para orquestar procesos en pasos encadenados.
Sirven mucho cuando un proceso puede fallar en la mitad y querés controlar rollback o contexto compartidos. Procesos complejos encadenados con control de errores.
- ViewComponents → Cuando querés vistas reutilizables, testeables y con lógica encapsulada.
Son mejores que partials cuando el bloque tiene lógica propia y puede tener props/slots. Vistas reutilizables y testeables con lógica propia.
- Partials → Para extraer repetición en vistas, sin necesidad de tanta lógica como un componente.
Ejemplo: formularios (_form.html.erb), pedazos de layout repetidos. Extracción simple de vistas repetidas.

## Resumen de Roles
- **Constructores (activo)**: acceso completo a gestión de proyectos, documentación, pagos, colaboración e inventario descritos arriba.
- **Compradores y vendedores (en espera)**: los flujos comerciales, la gestión de catálogos y el descubrimiento de proveedores siguen planificados pero inactivos en el hito actual.
- **Administradores**: los dueños de la plataforma mantienen acceso a las herramientas administrativas mientras se liberan nuevas funciones para constructores.

Mantén la experiencia del constructor ágil para iterar: las nuevas funcionalidades deben ubicarse por defecto en el namespace de constructor y reutilizar componentes compartidos solo cuando soporten comportamiento sensible al rol. Las iniciativas orientadas al marketplace pueden construirse sobre esta base una vez que la operación del constructor esté estabilizada.

