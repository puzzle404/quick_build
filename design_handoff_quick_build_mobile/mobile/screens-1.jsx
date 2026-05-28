// Mobile screens · Part 1 — Onboarding + Tabs (Inicio, Proyectos, Buscar, Biblioteca, Perfil)

// ============================================================
// 01. Welcome / Splash
// ============================================================
function ScreenWelcome() {
  return (
    <div className="m-screen" style={{
      background: 'linear-gradient(180deg, oklch(96% 0.04 255) 0%, var(--color-bg) 60%)',
      paddingTop: 80
    }}>
      <div style={{ padding: '40px 28px 0', flex: 1, display: 'flex', flexDirection: 'column' }}>
        {/* Logo */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 36 }}>
          <div style={{ width: 48, height: 48, borderRadius: 14, background: 'var(--color-ink)', color: 'var(--color-bg)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'var(--font-mono)', fontWeight: 700, fontSize: 24, letterSpacing: -1 }}>◱</div>
          <div>
            <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: -0.4 }}>Quick Build</div>
            <div className="mono" style={{ fontSize: 11, color: 'var(--color-ink-3)', letterSpacing: 1, textTransform: 'uppercase' }}>Obra · OS</div>
          </div>
        </div>

        <div style={{ flex: 1 }}>
          <h1 style={{ margin: '0 0 12px', fontSize: 34, lineHeight: 1.1, fontWeight: 700, letterSpacing: -0.8, color: 'var(--color-ink)' }}>
            Tu obra,<br />en una sola<br />palma.
          </h1>
          <p style={{ margin: '0 0 24px', fontSize: 16, color: 'var(--color-ink-3)', lineHeight: 1.45 }}>
            Planos, etapas, materiales y equipo — sincronizados entre escritorio y obra.
          </p>

          {/* Mini feature list */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 20 }}>
            {[
            { i: 'stages', t: 'Etapas + Gantt y curva S' },
            { i: 'materials', t: 'Listas de materiales y costos' },
            { i: 'blueprint', t: 'Planos con análisis IA' }].
            map((f) =>
            <div key={f.i} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{ width: 32, height: 32, borderRadius: 10, background: 'var(--color-bg-raised)', border: '1px solid var(--color-line)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--color-accent)' }}>
                  <MIcon name={f.i} size={17} />
                </div>
                <span style={{ fontSize: 14.5, fontWeight: 500 }}>{f.t}</span>
              </div>
            )}
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, paddingBottom: 36 }}>
          <MButton variant="primary" size="lg" full iconRight="arrow-right">Crear cuenta</MButton>
          <MButton variant="ghost" size="lg" full>Ya tengo cuenta</MButton>
        </div>
      </div>
    </div>);

}

// ============================================================
// 02. Login
// ============================================================
function ScreenLogin() {
  return (
    <div className="m-screen">
      <MNavBar back title="Ingresar" right={null} />
      <div style={{ padding: '20px 24px 24px', flex: 1 }}>
        <h1 style={{ margin: '0 0 8px', fontSize: 30, fontWeight: 700, letterSpacing: -0.6 }}>Hola de nuevo</h1>
        <p style={{ margin: '0 0 28px', color: 'var(--color-ink-3)', fontSize: 15 }}>Ingresá con tu email y contraseña.</p>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <FormField label="Email" value="maria@fernandez-cc.com.ar" />
          <FormField label="Contraseña" value="••••••••" trailing={<MIcon name="user" size={16} color="var(--color-ink-3)" />} />
        </div>

        <div style={{ textAlign: 'right', marginTop: 10 }}>
          <a style={{ fontSize: 13, color: 'var(--color-accent)', textDecoration: 'none', fontWeight: 500 }}>¿Olvidaste tu contraseña?</a>
        </div>

        <div style={{ marginTop: 24 }}>
          <MButton variant="primary" size="lg" full>Ingresar</MButton>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 10, margin: '28px 0 20px' }}>
          <div style={{ flex: 1, height: 1, background: 'var(--color-line)' }} />
          <span style={{ fontSize: 12, color: 'var(--color-ink-3)', textTransform: 'uppercase', fontFamily: 'var(--font-mono)', letterSpacing: 0.6 }}>o</span>
          <div style={{ flex: 1, height: 1, background: 'var(--color-line)' }} />
        </div>
        <MButton variant="secondary" size="lg" full>
          <span style={{ fontSize: 18, marginRight: 4 }}></span> Continuar con Apple
        </MButton>
      </div>
    </div>);

}

function FormField({ label, value, trailing, helper }) {
  return (
    <div>
      <label style={{ display: 'block', fontSize: 12, fontWeight: 600, color: 'var(--color-ink-2)', marginBottom: 6, letterSpacing: -0.1 }}>{label}</label>
      <div style={{
        display: 'flex', alignItems: 'center', gap: 10,
        background: 'var(--color-bg-raised)', border: '1px solid var(--color-line-2)',
        borderRadius: 12, padding: '0 14px', minHeight: 48
      }}>
        <input defaultValue={value} style={{ flex: 1, border: 'none', outline: 'none', background: 'transparent', fontSize: 15, color: 'var(--color-ink)', padding: '14px 0' }} />
        {trailing}
      </div>
      {helper && <div style={{ fontSize: 11.5, color: 'var(--color-ink-3)', marginTop: 5 }}>{helper}</div>}
    </div>);

}

// ============================================================
// 03. Sign up
// ============================================================
function ScreenSignup() {
  return (
    <div className="m-screen">
      <MNavBar back title="Crear cuenta" />
      <div style={{ padding: '12px 24px 24px', flex: 1 }}>
        <h1 style={{ margin: '0 0 8px', fontSize: 28, fontWeight: 700, letterSpacing: -0.6 }}>Empezá en 60 segundos</h1>
        <p style={{ margin: '0 0 24px', color: 'var(--color-ink-3)', fontSize: 14.5, lineHeight: 1.45 }}>Después podés invitar a tu equipo y vincular tu primer proyecto.</p>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <FormField label="Nombre y apellido" value="María Fernández" />
          <FormField label="Empresa / Razón social" value="Fernández Construcciones SAS" />
          <FormField label="Email de trabajo" value="maria@fernandez-cc.com.ar" />
          <FormField label="Contraseña" value="" helper="Mín. 8 caracteres, una mayúscula y un número." />
        </div>

        <label style={{ display: 'flex', gap: 10, marginTop: 16, fontSize: 12.5, color: 'var(--color-ink-2)', lineHeight: 1.4 }}>
          <input type="checkbox" defaultChecked style={{ accentColor: 'var(--color-accent)', marginTop: 2, flexShrink: 0 }} />
          <span>Acepto los <a style={{ color: 'var(--color-accent)' }}>Términos</a> y la <a style={{ color: 'var(--color-accent)' }}>Política de privacidad</a>.</span>
        </label>

        <div style={{ marginTop: 20 }}>
          <MButton variant="primary" size="lg" full iconRight="arrow-right">Crear cuenta</MButton>
        </div>
      </div>
    </div>);

}

// ============================================================
// 04. Dashboard / Inicio
// ============================================================
function ScreenDashboard() {
  return (
    <div className="m-screen">
      {/* Header */}
      <div style={{ padding: '10px 20px 8px', display: 'flex', alignItems: 'center', gap: 12 }}>
        <MAvatar name="María Fernández" size={36} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 12, color: 'var(--color-ink-3)' }}>Buenas tardes,</div>
          <div style={{ fontSize: 15, fontWeight: 600 }}>María</div>
        </div>
        <button style={{ width: 36, height: 36, borderRadius: 999, background: 'var(--color-bg-raised)', border: '1px solid var(--color-line)', display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
          <MIcon name="bell" size={18} color="var(--color-ink-2)" />
          <span style={{ position: 'absolute', top: 6, right: 6, width: 8, height: 8, borderRadius: 999, background: 'var(--color-warn)', border: '1.5px solid var(--color-bg-raised)' }} />
        </button>
      </div>

      <div style={{ flex: 1, overflow: 'auto', paddingTop: 6 }}>
        {/* Greeting + headline */}
        <div style={{ padding: '10px 20px 18px' }}>
          <h1 style={{ margin: 0, fontSize: 28, fontWeight: 700, letterSpacing: -0.5, lineHeight: 1.1 }}>
            <span style={{ color: 'var(--color-ink-3)' }}>5 obras activas ·</span><br />
            <span style={{ color: 'var(--color-warn)' }}>2 requieren atención</span>
          </h1>
        </div>

        {/* Hero cards 2x2 */}
        <div style={{ padding: '0 16px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 18 }}>
          <MKpi gradient="violet" icon="projects" label="Obras totales" value="7" hint="5 activas · 2 finalizadas" />
          <MKpi gradient="amber" icon="stages" label="En curso" value="5" hint="71% del total" />
          <MKpi gradient="sky" icon="calendar" label="Planificadas" value="2" hint="próximas a iniciar" />
          <MKpi gradient="emerald" icon="check" label="Completadas" value="14%" hint="del avance global" />
        </div>

        {/* Secondary KPIs (mini row) */}
        <MSection title="Operativo">
          <MCard padding={0}>
            <MRow icon="people" iconBg="color-mix(in oklab, var(--color-info) 14%, transparent)" title="73 personas en obra" subtitle="+4 vs ayer · 4 obras activas" value="" chevron />
            <MRow icon="money" iconBg="color-mix(in oklab, var(--color-accent) 14%, transparent)" title="Presupuesto comprometido" subtitle="61% ejecutado del total" value="$ 198M" hint />
            <MRow icon="materials" iconBg="color-mix(in oklab, var(--color-warn) 14%, transparent)" title="14 órdenes abiertas" subtitle="3 vencen esta semana" value="" chevron isLast />
          </MCard>
        </MSection>

        {/* Active projects */}
        <MSection title="Obras activas · 5" action={<a style={{ fontSize: 13, color: 'var(--color-accent)', fontWeight: 600 }}>Ver todas</a>}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            <ProjectMiniCard p={SAMPLE_PROJECTS[0]} />
            <ProjectMiniCard p={SAMPLE_PROJECTS[1]} />
            <ProjectMiniCard p={SAMPLE_PROJECTS[2]} />
          </div>
        </MSection>

        {/* Alerts */}
        <MSection title="Alertas · hoy">
          <MCard padding={0}>
            <AlertRow tone="bad" title="Sobrecosto +18% vs presupuesto" sub="PRJ-040 · Quincho Nordelta · 09:14" />
            <AlertRow tone="warn" title="Etapa Hormigonado con 11d de retraso" sub="PRJ-039 · Casa Pilar · 48 min" />
            <AlertRow tone="warn" title="3 docs vencidos pendientes de firma" sub="PRJ-042 · Torre Aurora · 2 h" isLast />
          </MCard>
        </MSection>

        {/* Activity */}
        <MSection title="Actividad reciente">
          <MCard padding={0}>
            <ActivityRow icon="upload" who="M. Pérez" what="subió plano A-04.pdf" project="PRJ-042" when="12 min" />
            <ActivityRow icon="stages" who="J. Silva" what="cerró etapa Sanitarias" project="PRJ-042" when="1 h" />
            <ActivityRow icon="materials" who="F. López" what="agregó 140 bolsas de cemento" project="PRJ-042" when="2 h" />
            <ActivityRow icon="sparkles" who="IA Blueprint" what="completó análisis A-01" project="PRJ-044" when="3 h" isLast />
          </MCard>
        </MSection>

        <div style={{ height: 80 }} />
      </div>

      <MTabBar active="home" />
    </div>);

}

const SAMPLE_PROJECTS = [
{ code: 'PRJ-042', name: 'Torre Palermo · Aurora', client: 'Inmobiliaria Delta', loc: 'Av. Santa Fe 3421', status: 'in_progress', health: 'ok', progress: 64, plan: 68, budget: 84_500_000, spent: 51_200_000, stages: 14, stagesDone: 8, people: 22, dueAt: '2026-08-18' },
{ code: 'PRJ-039', name: 'Casa Pilar · Lote 14', client: 'Familia Ibarra', loc: 'Pilar, BA', status: 'in_progress', health: 'warn', progress: 31, plan: 42, budget: 18_200_000, spent: 9_100_000, stages: 9, stagesDone: 3, people: 8, dueAt: '2026-07-30' },
{ code: 'PRJ-037', name: 'Ampliación Depósito VL', client: 'Logística Norte', loc: 'V. López', status: 'in_progress', health: 'ok', progress: 82, plan: 80, budget: 32_700_000, spent: 26_800_000, stages: 11, stagesDone: 9, people: 14, dueAt: '2026-05-10' },
{ code: 'PRJ-040', name: 'Quincho + Pileta Nordelta', client: 'Martín Ríos', loc: 'Nordelta, Tigre', status: 'in_progress', health: 'bad', progress: 48, plan: 72, budget: 9_400_000, spent: 6_800_000, stages: 6, stagesDone: 3, people: 5, dueAt: '2026-04-22' },
{ code: 'PRJ-044', name: 'Local Comercial Recoleta', client: 'Grupo Estrella', loc: 'Callao 1120', status: 'planned', health: 'ok', progress: 0, plan: 0, budget: 14_800_000, spent: 0, stages: 7, stagesDone: 0, people: 0, dueAt: '2026-11-15' }];


function ProjectMiniCard({ p, onClick }) {
  const statusLabel = { in_progress: 'En obra', planned: 'Planificado', completed: 'Finalizado' }[p.status];
  return (
    <MCard onClick={onClick} padding={14}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
        <MDot tone={p.health} />
        <span className="mono" style={{ fontSize: 10.5, color: 'var(--color-ink-4)', letterSpacing: 0.5 }}>{p.code}</span>
        <MPill tone={p.status === 'in_progress' ? 'info' : p.status === 'completed' ? 'ok' : 'muted'} dense>{statusLabel}</MPill>
        <div style={{ flex: 1 }} />
        <span className="mono tnum" style={{ fontSize: 18, fontWeight: 600, letterSpacing: -0.4 }}>{p.progress}%</span>
      </div>
      <div style={{ fontSize: 15, fontWeight: 600, lineHeight: 1.25, marginBottom: 4 }}>{p.name}</div>
      <div style={{ fontSize: 12, color: 'var(--color-ink-3)', marginBottom: 10 }}>{p.client} · {p.loc}</div>
      <MBar value={p.progress} plan={p.plan} showPlan tone={p.health === 'bad' ? 'bad' : p.health === 'warn' ? 'warn' : 'accent'} height={5} />
      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11.5, color: 'var(--color-ink-3)', marginTop: 8 }}>
        <span><span className="mono tnum">{p.stagesDone}/{p.stages}</span> etapas · {p.people} pers</span>
        <span className="mono tnum">{fmtARS(p.spent)} / {fmtARS(p.budget)}</span>
      </div>
    </MCard>);

}

function AlertRow({ tone, title, sub, isLast }) {
  return (
    <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12, padding: '12px 14px', borderBottom: isLast ? 'none' : '1px solid var(--color-line)' }}>
      <div style={{ marginTop: 4 }}><MDot tone={tone} /></div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 500, color: 'var(--color-ink)' }}>{title}</div>
        <div style={{ fontSize: 11.5, color: 'var(--color-ink-3)', marginTop: 2 }}>{sub}</div>
      </div>
      <MIcon name="chev-right" size={16} color="var(--color-ink-4)" />
    </div>);

}

function ActivityRow({ icon, who, what, project, when, isLast }) {
  return (
    <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12, padding: '12px 14px', borderBottom: isLast ? 'none' : '1px solid var(--color-line)' }}>
      <div style={{ width: 28, height: 28, borderRadius: 8, background: 'var(--color-bg-sunken)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--color-ink-2)', flexShrink: 0 }}>
        <MIcon name={icon} size={14} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13.5, color: 'var(--color-ink-2)', lineHeight: 1.35 }}>
          <span style={{ color: 'var(--color-ink)', fontWeight: 600 }}>{who}</span> {what}
        </div>
        <div style={{ fontSize: 11, color: 'var(--color-ink-4)', marginTop: 2 }}>
          <span className="mono">{project}</span> · hace {when}
        </div>
      </div>
    </div>);

}

// ============================================================
// 05. Proyectos (lista)
// ============================================================
function ScreenProjects() {
  return (
    <div className="m-screen">
      <div style={{ padding: '10px 20px 4px', display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 12, color: 'var(--color-ink-3)' }}>Fernández Const.</div>
          <h1 style={{ margin: 0, fontSize: 28, fontWeight: 700, letterSpacing: -0.5 }}>Proyectos</h1>
        </div>
        <button style={{ width: 40, height: 40, borderRadius: 999, background: 'var(--color-accent)', color: 'var(--color-accent-ink)', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <MIcon name="plus" size={22} stroke={2.4} />
        </button>
      </div>

      {/* Search */}
      <div style={{ padding: '10px 20px 8px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, background: 'var(--color-bg-sunken)', border: '1px solid var(--color-line)', borderRadius: 12, padding: '0 12px', height: 42 }}>
          <MIcon name="search" size={17} color="var(--color-ink-3)" />
          <input placeholder="Buscar por nombre, código, cliente…" style={{ flex: 1, border: 'none', outline: 'none', background: 'transparent', fontSize: 14 }} />
          <button style={{ background: 'transparent', border: 'none', display: 'flex' }}><MIcon name="filter" size={18} color="var(--color-ink-3)" /></button>
        </div>
      </div>

      {/* Status filters — underline tabs (new design system) */}
      <div style={{ padding: '4px 16px 0', borderBottom: '1px solid var(--color-line)', overflowX: 'auto', display: 'flex', gap: 18, scrollbarWidth: 'none' }}>
        {[
        { k: 'all', l: 'Todos', c: 7, active: true },
        { k: 'in_progress', l: 'En obra', c: 5 },
        { k: 'planned', l: 'Planificados', c: 2 },
        { k: 'completed', l: 'Finalizados', c: 0 }].
        map((f) =>
        <button key={f.k} style={{
          padding: '10px 0', border: 'none', background: 'transparent',
          borderBottom: `2px solid ${f.active ? 'var(--color-accent)' : 'transparent'}`,
          color: f.active ? 'var(--color-ink)' : 'var(--color-ink-3)',
          fontWeight: f.active ? 700 : 500, fontSize: 13.5,
          marginBottom: -1, display: 'inline-flex', alignItems: 'center', gap: 6,
          whiteSpace: 'nowrap'
        }}>
            {f.l}
            <span style={{
            fontFamily: 'var(--font-mono)', fontSize: 10.5, fontWeight: 700,
            padding: '1px 6px', borderRadius: 4,
            background: f.active ? 'color-mix(in oklab, var(--color-accent) 14%, transparent)' : 'var(--color-bg-sunken)',
            color: f.active ? 'var(--color-accent)' : 'var(--color-ink-4)'
          }}>{f.c}</span>
          </button>
        )}
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '8px 16px 8px' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {SAMPLE_PROJECTS.slice(0, 5).map((p) => <ProjectMiniCard key={p.code} p={p} />)}
        </div>
        <div style={{ height: 80 }} />
      </div>

      <MTabBar active="projects" />
    </div>);

}

// ============================================================
// 06. Buscar
// ============================================================
function ScreenSearch() {
  return (
    <div className="m-screen">
      <div style={{ padding: '12px 20px 8px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, background: 'var(--color-bg-sunken)', border: '1px solid var(--color-line)', borderRadius: 12, padding: '0 12px', height: 46 }}>
          <MIcon name="search" size={18} color="var(--color-ink-3)" />
          <input autoFocus placeholder="Buscar…" defaultValue="hierro" style={{ flex: 1, border: 'none', outline: 'none', background: 'transparent', fontSize: 15 }} />
          <button style={{ background: 'transparent', border: 'none', color: 'var(--color-accent)', fontSize: 14, fontWeight: 600 }}>Cancelar</button>
        </div>
      </div>

      {/* Scoped filters — underline tabs (new design system) */}
      <MTabs value="all" options={[
        { k: 'all',        l: 'Todo',       active: true },
        { k: 'projects',   l: 'Proyectos' },
        { k: 'stages',     l: 'Etapas' },
        { k: 'materials',  l: 'Materiales' },
        { k: 'documents',  l: 'Documentos' },
        { k: 'people',     l: 'Personas' },
      ]}/>

      <div style={{ flex: 1, overflow: 'auto' }}>
        <MSection title="Materiales · 4">
          <MCard padding={0}>
            <MRow icon="materials" title="Hierro ø12 12m ADN 420" subtitle="Lista: Hierros · Estructura" value="420 barras" />
            <MRow icon="materials" title="Hierro ø8 12m ADN 420" subtitle="Lista: Hierros · Estructura" value="640 barras" />
            <MRow icon="materials" title="Hierro ø6 12m ADN 420" subtitle="Lista: Hierros · Estructura" value="180 barras" />
            <MRow icon="materials" title="Alambre recocido Nº14" subtitle="Lista: Hierros · Estructura" value="40 kg" isLast />
          </MCard>
        </MSection>

        <MSection title="Etapas · 2">
          <MCard padding={0}>
            <MRow icon="stages" title="Estructura · Columnas y losas" subtitle="PRJ-042 · 78% avance" />
            <MRow icon="stages" title="Estructura · Cómputo hierros" subtitle="PRJ-039 · Próxima" isLast />
          </MCard>
        </MSection>

        <MSection title="Documentos · 1">
          <MCard padding={0}>
            <MRow icon="doc" title="Cotización hierros · Acindar.pdf" subtitle="PRJ-042 · 22 Feb · 380 KB" isLast />
          </MCard>
        </MSection>
        <div style={{ height: 80 }} />
      </div>

      <MTabBar active="search" />
    </div>);

}

// ============================================================
// 07. Biblioteca
// ============================================================
function ScreenLibrary() {
  return (
    <div className="m-screen">
      <MPageHeader eyebrow="Recursos del estudio" title="Biblioteca"
      subtitle="Plantillas, listas reutilizables y proveedores frecuentes."
      action={<button style={{ width: 36, height: 36, borderRadius: 999, background: 'var(--color-bg-raised)', border: '1px solid var(--color-line)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <MIcon name="plus" size={20} color="var(--color-accent)" />
        </button>} />

      <div style={{ flex: 1, overflow: 'auto' }}>
        <MSection title="Plantillas de etapas">
          <MCard padding={0}>
            <MRow icon="stages" iconBg="color-mix(in oklab, var(--color-accent) 14%, transparent)" title="Obra nueva completa" subtitle="14 etapas + 6 sub-etapas" value="3 obras" />
            <MRow icon="stages" iconBg="color-mix(in oklab, var(--color-info) 14%, transparent)" title="Reforma integral" subtitle="10 etapas + 4 sub-etapas" value="1 obra" />
            <MRow icon="stages" iconBg="color-mix(in oklab, var(--color-warn) 14%, transparent)" title="Ampliación menor" subtitle="7 etapas" value="—" isLast />
          </MCard>
        </MSection>

        <MSection title="Listas de materiales reutilizables">
          <MCard padding={0}>
            <MRow icon="materials" title="Hormigón y hierros · Fundaciones" subtitle="8 ítems · base aprobada" value="$ 9.4M" />
            <MRow icon="materials" title="Sanitarios estándar baño" subtitle="14 ítems" value="$ 1.8M" />
            <MRow icon="materials" title="Eléctricos · Vivienda 3 amb." subtitle="22 ítems" value="$ 3.2M" isLast />
          </MCard>
        </MSection>

        <MSection title="Proveedores frecuentes">
          <MCard padding={0}>
            <MRow icon="people" title="Acindar" subtitle="Hierros · 12 órdenes" value="★ 4.8" />
            <MRow icon="people" title="Loma Negra" subtitle="Cemento · 9 órdenes" value="★ 4.6" />
            <MRow icon="people" title="Cerámica del Plata" subtitle="Ladrillos · 7 órdenes" value="★ 4.4" isLast />
          </MCard>
        </MSection>
        <div style={{ height: 80 }} />
      </div>

      <MTabBar active="library" />
    </div>);

}

// ============================================================
// 08. Perfil / Ajustes
// ============================================================
function ScreenProfile() {
  return (
    <div className="m-screen">
      <div style={{ padding: '24px 20px 16px', display: 'flex', alignItems: 'center', gap: 14 }}>
        <MAvatar name="María Fernández" size={64} />
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 18, fontWeight: 700 }}>María Fernández</div>
          <div style={{ fontSize: 13, color: 'var(--color-ink-3)' }}>Jefa de obra · Fernández Const.</div>
          <div style={{ marginTop: 6 }}><MPill tone="accent" dense>Plan Pro</MPill></div>
        </div>
        <button style={{ background: 'transparent', border: '1px solid var(--color-line)', borderRadius: 999, padding: '8px 12px', fontSize: 13, fontWeight: 600, color: 'var(--color-ink-2)' }}>Editar</button>
      </div>

      <div style={{ flex: 1, overflow: 'auto' }}>
        <MSection title="Cuenta">
          <MCard padding={0}>
            <MRow icon="people" title="Equipo y permisos" subtitle="12 miembros activos" />
            <MRow icon="shield" title="Seguridad" subtitle="Contraseña · 2FA" />
            <MRow icon="bell" title="Notificaciones" subtitle="3 activas" isLast />
          </MCard>
        </MSection>

        <MSection title="Apariencia">
          <MCard padding={0}>
            <MRow icon="cog" title="Tema" value="Auto" />
            <MRow icon="cog" title="Densidad" value="Cómoda" />
            <MRow icon="cog" title="Idioma" value="Español (AR)" isLast />
          </MCard>
        </MSection>

        <MSection title="Datos">
          <MCard padding={0}>
            <MRow icon="download" title="Exportar respaldo" />
            <MRow icon="upload" title="Importar desde Excel" />
            <MRow icon="qr" title="Vincular dispositivo" subtitle="2 sesiones activas" isLast />
          </MCard>
        </MSection>

        <MSection title="">
          <MCard padding={0}>
            <MRow icon="more" title="Ayuda y soporte" />
            <MRow icon="more" title="Términos y privacidad" />
            <div style={{ padding: '14px 14px 12px', textAlign: 'center', borderTop: '1px solid var(--color-line)' }}>
              <button style={{ background: 'transparent', border: 'none', color: 'var(--color-bad)', fontSize: 14.5, fontWeight: 600 }}>Cerrar sesión</button>
            </div>
          </MCard>
        </MSection>

        <div style={{ textAlign: 'center', padding: '12px 0 80px', fontSize: 11, fontFamily: 'var(--font-mono)', color: 'var(--color-ink-4)' }}>
          Quick Build · iOS 2.4.0
        </div>
      </div>

      <MTabBar active="me" />
    </div>);

}

Object.assign(window, {
  ScreenWelcome, ScreenLogin, ScreenSignup,
  ScreenDashboard, ScreenProjects, ScreenSearch, ScreenLibrary, ScreenProfile,
  ProjectMiniCard, SAMPLE_PROJECTS
});