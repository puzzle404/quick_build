// Mobile screens · Part 2 — Project detail, Stages, Stage detail, modals

// ============================================================
// 09. Project detail — Overview / Resumen
// ============================================================
function ScreenProjectOverview() {
  const p = SAMPLE_PROJECTS[0]; // PRJ-042 Torre Aurora
  return (
    <div className="m-screen">
      <MNavBar back title="" right={
      <button style={{ background: 'transparent', border: 'none', display: 'flex' }}><MIcon name="more" size={22} color="var(--color-ink-2)" /></button>
      } />

      <div style={{ flex: 1, overflow: 'auto' }}>
        {/* Hero header */}
        <div style={{ padding: '4px 20px 16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
            <span className="mono" style={{ fontSize: 11, color: 'var(--color-ink-3)', background: 'var(--color-bg-sunken)', padding: '3px 8px', borderRadius: 4, fontWeight: 600 }}>{p.code}</span>
            <MPill tone="info" dense>En obra</MPill>
            <MPill tone="ok" dense>Saludable</MPill>
          </div>
          <h1 style={{ margin: '4px 0 6px', fontSize: 24, fontWeight: 700, letterSpacing: -0.4, lineHeight: 1.15 }}>{p.name}</h1>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px 14px', fontSize: 13, color: 'var(--color-ink-3)' }}>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}><MIcon name="people" size={13} />{p.client}</span>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}><MIcon name="map-pin" size={13} />{p.loc}</span>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}><MIcon name="calendar" size={13} />Entrega 18 Ago</span>
          </div>
        </div>

        {/* Big progress hero */}
        <div style={{ padding: '0 16px 14px' }}>
          <MCard padding={16} style={{ background: 'linear-gradient(135deg, oklch(50% 0.20 250) 0%, oklch(60% 0.22 235) 100%)', border: 'none', color: 'white' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
              <div>
                <div style={{ fontSize: 11, fontFamily: 'var(--font-mono)', color: 'rgba(255,255,255,0.8)', textTransform: 'uppercase', letterSpacing: 0.7, fontWeight: 600 }}>Avance global</div>
                <div className="mono tnum" style={{ fontSize: 44, fontWeight: 600, letterSpacing: -1.5, lineHeight: 1, marginTop: 4 }}>{p.progress}%</div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontSize: 11, fontFamily: 'var(--font-mono)', color: 'rgba(255,255,255,0.7)', textTransform: 'uppercase', letterSpacing: 0.7, fontWeight: 600 }}>Plan</div>
                <div className="mono tnum" style={{ fontSize: 22, fontWeight: 600, opacity: 0.9, marginTop: 4 }}>{p.plan}%</div>
                <div style={{ fontSize: 11.5, color: 'rgba(255,255,255,0.85)', marginTop: 2, fontWeight: 600 }}>Δ {p.progress - p.plan}</div>
              </div>
            </div>
            <div style={{ height: 6, borderRadius: 999, background: 'rgba(255,255,255,0.18)', overflow: 'hidden', position: 'relative' }}>
              <div style={{ height: '100%', width: `${p.progress}%`, background: 'white', borderRadius: 999 }} />
              <div style={{ position: 'absolute', top: -3, bottom: -3, left: `${p.plan}%`, width: 2, background: 'rgba(255,255,255,0.7)' }} />
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 10, fontSize: 11.5, color: 'rgba(255,255,255,0.85)' }}>
              <span>8 de 14 etapas completadas</span>
              <span>122 días restantes</span>
            </div>
          </MCard>
        </div>

        {/* Quick stats 2x2 */}
        <div style={{ padding: '0 16px 18px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          <MCard padding={12}>
            <div style={{ fontSize: 11, fontFamily: 'var(--font-mono)', color: 'var(--color-ink-3)', textTransform: 'uppercase', letterSpacing: 0.7, fontWeight: 600 }}>Presupuesto</div>
            <div className="mono tnum" style={{ fontSize: 18, fontWeight: 700, marginTop: 3, letterSpacing: -0.3 }}>$ 51.2M</div>
            <div style={{ fontSize: 11, color: 'var(--color-ink-3)', marginTop: 2 }}>61% de $ 84.5M</div>
            <div style={{ marginTop: 8 }}><MBar value={61} tone="accent" height={4} /></div>
          </MCard>
          <MCard padding={12}>
            <div style={{ fontSize: 11, fontFamily: 'var(--font-mono)', color: 'var(--color-ink-3)', textTransform: 'uppercase', letterSpacing: 0.7, fontWeight: 600 }}>Equipo hoy</div>
            <div className="mono tnum" style={{ fontSize: 18, fontWeight: 700, marginTop: 3, letterSpacing: -0.3 }}>22 pers</div>
            <div style={{ fontSize: 11, color: 'var(--color-ok)', marginTop: 2, fontWeight: 600 }}>+2 vs ayer</div>
            <div style={{ display: 'flex', marginTop: 8, gap: -4 }}>
              {['Rodrigo Díaz', 'Federico López', 'Martín Pérez', 'Javier Silva'].map((n, i) =>
              <div key={n} style={{ marginLeft: i === 0 ? 0 : -8, border: '2px solid var(--color-bg-raised)', borderRadius: 999 }}>
                  <MAvatar name={n} size={22} />
                </div>
              )}
              <div style={{ marginLeft: -8, width: 22, height: 22, borderRadius: 999, background: 'var(--color-bg-sunken)', border: '2px solid var(--color-bg-raised)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 9, fontWeight: 700, color: 'var(--color-ink-3)' }}>+18</div>
            </div>
          </MCard>
        </div>

        {/* Section nav (mobile cards grid) */}
        <MSection title="En este proyecto">
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <SectionTile icon="stages" label="Planificación" sub="14 etapas · 4 en riesgo" tone="warn" />
            <SectionTile icon="materials" label="Materiales" sub="9 listas · $ 46M" tone="accent" />
            <SectionTile icon="blueprint" label="Planos · IA" sub="12 planos · 1 IA procesando" tone="accent" badge="AI" />
            <SectionTile icon="people" label="Equipo" sub="22 personas activas" tone="info" />
            <SectionTile icon="doc" label="Documentos" sub="47 archivos" tone="muted" />
            <SectionTile icon="money" label="Gastos" sub="$ 51.2M · 18 registros" tone="muted" />
          </div>
        </MSection>

        {/* Risks */}
        <MSection title="Riesgos y bloqueos · 3">
          <MCard padding={0}>
            <RiskRow tone="bad" title="Hierro ø12 no recibido" sub="Acindar reporta demora de 9 días. Impacta Estructura." />
            <RiskRow tone="warn" title="Permiso municipal pendiente" sub="Vence 28/04. Estudio Pérez en revisión." />
            <RiskRow tone="warn" title="Planos eléctricos rev.2" sub="J. Silva marcó inconsistencias en A-06." isLast />
          </MCard>
        </MSection>

        {/* Upcoming stages */}
        <MSection title="Próximas etapas">
          <MCard padding={0}>
            <MRow icon="stages" title="Revoques" subtitle="Empieza en 3d · M. Pérez" value="$ 3.8M" />
            <MRow icon="stages" title="Pisos y revestimientos" subtitle="Empieza en 6d · A. Gómez" value="$ 5.8M" />
            <MRow icon="stages" title="Cielorrasos" subtitle="Empieza en 9d · M. Pérez" value="$ 2.1M" isLast />
          </MCard>
        </MSection>

        <div style={{ height: 80 }} />
      </div>
    </div>);

}

function SectionTile({ icon, label, sub, tone, badge }) {
  const bg = tone === 'warn' ? 'color-mix(in oklab, var(--color-warn) 14%, transparent)' :
  tone === 'accent' ? 'color-mix(in oklab, var(--color-accent) 14%, transparent)' :
  tone === 'info' ? 'color-mix(in oklab, var(--color-info) 14%, transparent)' :
  'var(--color-bg-sunken)';
  const fg = tone === 'warn' ? 'var(--color-warn)' :
  tone === 'accent' ? 'var(--color-accent)' :
  tone === 'info' ? 'var(--color-info)' :
  'var(--color-ink-2)';
  return (
    <MCard padding={14} style={{ position: 'relative' }}>
      {badge && <span style={{ position: 'absolute', top: 10, right: 10, fontSize: 9, fontFamily: 'var(--font-mono)', fontWeight: 700, padding: '2px 6px', background: 'var(--color-accent)', color: 'var(--color-accent-ink)', borderRadius: 4, letterSpacing: 0.5 }}>{badge}</span>}
      <div style={{ width: 32, height: 32, borderRadius: 8, background: bg, color: fg, display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 10 }}>
        <MIcon name={icon} size={17} />
      </div>
      <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--color-ink)' }}>{label}</div>
      <div style={{ fontSize: 11.5, color: 'var(--color-ink-3)', marginTop: 2, lineHeight: 1.35 }}>{sub}</div>
    </MCard>);

}

function RiskRow({ tone, title, sub, isLast }) {
  return (
    <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12, padding: '12px 14px', borderBottom: isLast ? 'none' : '1px solid var(--color-line)' }}>
      <div style={{ marginTop: 5 }}><MDot tone={tone} /></div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--color-ink)' }}>{title}</div>
        <div style={{ fontSize: 12, color: 'var(--color-ink-3)', marginTop: 3, lineHeight: 1.4 }}>{sub}</div>
      </div>
    </div>);

}

// ============================================================
// 10. Stages list (Planning)
// ============================================================
function ScreenStages() {
  return (
    <div className="m-screen">
      <MNavBar back title="Torre Aurora" right={
      <button style={{ background: 'transparent', border: 'none' }}><MIcon name="plus" size={22} color="var(--color-accent)" /></button>
      } />

      <div style={{ padding: '4px 20px 12px' }}>
        <h1 style={{ margin: 0, fontSize: 24, fontWeight: 700, letterSpacing: -0.5 }}>Planificación</h1>
        <div style={{ fontSize: 13, color: 'var(--color-ink-3)', marginTop: 4 }}>14 etapas · 8 completadas · 4 en curso · 2 pendientes</div>
      </div>

      {/* View segmented */}
      <div style={{ padding: '4px 20px 12px' }}>
        <MSegmented value="cards" onChange={() => {}} options={[
        { k: 'cards', l: 'Etapas' },
        { k: 'gantt', l: 'Gantt' },
        { k: 'wbs', l: 'WBS' }]
        } />
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '0 16px' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <StageCard code="1" name="Proyecto y gestión" status="done" dates="15 Oct → 30 Nov" progress={100} subs={6} />
          <StageCard code="2" name="Movimiento de suelos" status="done" dates="4 Nov → 22 Nov" progress={100} subs={0} />
          <StageCard code="3" name="Fundaciones" status="done" dates="18 Nov → 14 Dic" progress={100} subs={0} lead="R. Díaz" />
          <StageCard code="4" name="Estructura" status="done" dates="8 Dic → 20 Feb" progress={100} subs={3} lead="F. López" expanded budget="$ 14.1M / $ 14.3M" />
          <StageCard code="5" name="Mampostería" status="doing" dates="10 Feb → 5 Abr" progress={78} subs={0} lead="M. Pérez" people={10} budget="$ 5.8M / $ 7.4M" />
          <StageCard code="6" name="Instalaciones sanitarias" status="doing" dates="25 Feb → 20 Abr" progress={62} subs={0} lead="J. Silva" people={4} />
          <StageCard code="7" name="Revoques" status="upcoming" dates="10 Abr → 20 May" progress={12} subs={0} lead="M. Pérez" />
          <StageCard code="8" name="Pisos y revestimientos" status="pending" dates="25 May → 10 Jul" progress={0} subs={0} />
        </div>
        <div style={{ height: 100 }} />
      </div>

      {/* Floating actions */}
      <div style={{
        position: 'absolute', bottom: 24, left: 0, right: 0,
        display: 'flex', justifyContent: 'center', gap: 8, padding: '0 16px',
        pointerEvents: 'none'
      }}>
        <button style={{
          pointerEvents: 'auto', height: 50, borderRadius: 999, padding: '0 22px',
          background: 'var(--color-ink)', color: 'var(--color-bg)',
          border: 'none', display: 'inline-flex', alignItems: 'center', gap: 8,
          fontWeight: 600, fontSize: 15, boxShadow: '0 10px 30px -6px rgba(0,0,0,0.3)'
        }}>
          <MIcon name="plus" size={20} stroke={2.4} />Nueva etapa
        </button>
      </div>
    </div>);

}

function StageCard({ code, name, status, dates, progress, subs, lead, people, budget, expanded }) {
  const statusMap = {
    done: { tone: 'ok', label: 'Completada', color: 'var(--color-ok)' },
    doing: { tone: 'info', label: 'En curso', color: 'var(--color-accent)' },
    upcoming: { tone: 'warn', label: 'Atrasada', color: 'var(--color-warn)' },
    pending: { tone: 'muted', label: 'Pendiente', color: 'var(--color-ink-4)' }
  };
  const s = statusMap[status];
  return (
    <MCard padding={0}>
      <div style={{ padding: 14, display: 'flex', alignItems: 'flex-start', gap: 12 }}>
        <div style={{
          width: 38, height: 38, borderRadius: 10, flexShrink: 0,
          background: status === 'done' ? 'color-mix(in oklab, var(--color-ok) 16%, transparent)' : status === 'doing' ? 'color-mix(in oklab, var(--color-accent) 16%, transparent)' : 'var(--color-bg-sunken)',
          color: s.color,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'var(--font-mono)', fontWeight: 700, fontSize: 14
        }}>{code}</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3, flexWrap: 'wrap' }}>
            <span style={{ fontSize: 15, fontWeight: 600, color: 'var(--color-ink)' }}>{name}</span>
            <MPill tone={s.tone} dense>{s.label}</MPill>
          </div>
          <div style={{ fontSize: 12, color: 'var(--color-ink-3)', display: 'flex', flexWrap: 'wrap', gap: '2px 10px' }}>
            <span className="mono" style={{ display: 'inline-flex', alignItems: 'center', gap: 3 }}><MIcon name="calendar" size={11} />{dates}</span>
            {lead && <span>· {lead}</span>}
            {people && <span>· {people} pers</span>}
          </div>
        </div>
        <div style={{ textAlign: 'right', flexShrink: 0 }}>
          <div className="mono tnum" style={{ fontSize: 18, fontWeight: 700, color: s.color, letterSpacing: -0.3 }}>{progress}%</div>
          {subs > 0 && <div style={{ fontSize: 10.5, color: 'var(--color-ink-4)', marginTop: 1, fontFamily: 'var(--font-mono)' }}>{subs} sub</div>}
        </div>
      </div>
      <div style={{ padding: '0 14px 12px' }}>
        <MBar value={progress} tone={status === 'done' ? 'ok' : status === 'doing' ? 'accent' : status === 'upcoming' ? 'warn' : 'muted'} height={4} />
        {budget && <div style={{ fontSize: 11, color: 'var(--color-ink-3)', marginTop: 8, fontFamily: 'var(--font-mono)' }}>{budget}</div>}
      </div>
      {expanded &&
      <div style={{ borderTop: '1px solid var(--color-line)', padding: '8px 14px 12px', background: 'var(--color-bg-sunken)' }}>
          <div style={{ fontSize: 10.5, fontFamily: 'var(--font-mono)', color: 'var(--color-ink-3)', letterSpacing: 0.7, textTransform: 'uppercase', fontWeight: 600, padding: '6px 0 6px' }}>3 sub-etapas</div>
          <SubRow code="4.1" name="Columnas subsuelo" progress={100} />
          <SubRow code="4.2" name="Losas 1°–3°" progress={100} />
          <SubRow code="4.3" name="Columnas 4°–6°" progress={100} isLast />
        </div>
      }
    </MCard>);

}

function SubRow({ code, name, progress, isLast }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 0', borderBottom: isLast ? 'none' : '0.5px solid var(--color-line)' }}>
      <span className="mono tnum" style={{ fontSize: 11.5, color: 'var(--color-ink-3)', fontWeight: 600, minWidth: 30 }}>{code}</span>
      <div style={{ flex: 1, fontSize: 13.5, color: 'var(--color-ink)' }}>{name}</div>
      <div style={{ width: 36 }}><MBar value={progress} tone="ok" height={3} /></div>
      <span className="mono tnum" style={{ fontSize: 11, color: 'var(--color-ok)', minWidth: 30, textAlign: 'right', fontWeight: 600 }}>{progress}%</span>
    </div>);

}

// ============================================================
// 11. Stage detail (with internal tabs)
// ============================================================
function ScreenStageDetail() {
  return (
    <div className="m-screen">
      <MNavBar back title="" right={
      <button style={{ background: 'transparent', border: 'none' }}><MIcon name="more" size={22} color="var(--color-ink-2)" /></button>
      } />

      <div style={{ flex: 1, overflow: 'auto' }}>
        {/* Identity */}
        <div style={{ padding: '4px 20px 14px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
            <span className="mono" style={{ fontSize: 12, color: 'var(--color-ink-2)', background: 'var(--color-bg-sunken)', padding: '3px 9px', borderRadius: 4, fontWeight: 700 }}>5</span>
            <MPill tone="info" dense>En curso</MPill>
            <MPill tone="warn" dense>+3d atraso</MPill>
          </div>
          <h1 style={{ margin: '0 0 6px', fontSize: 24, fontWeight: 700, letterSpacing: -0.4, lineHeight: 1.15 }}>Mampostería</h1>
          <p style={{ margin: 0, fontSize: 13.5, color: 'var(--color-ink-3)', lineHeight: 1.45 }}>Muros interiores y exteriores, tabiques divisorios.</p>
        </div>

        {/* Big avance */}
        <div style={{ padding: '0 16px 14px' }}>
          <MCard padding={14}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 10 }}>
              <div className="mono tnum" style={{ fontSize: 36, fontWeight: 700, letterSpacing: -1, lineHeight: 1, color: 'var(--color-accent)' }}>78%</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 11, fontFamily: 'var(--font-mono)', color: 'var(--color-ink-3)', textTransform: 'uppercase', letterSpacing: 0.7, fontWeight: 600 }}>Avance</div>
                <div style={{ fontSize: 12, color: 'var(--color-ink-2)', marginTop: 2 }}>54 días transcurridos de 54</div>
              </div>
            </div>
            <MBar value={78} tone="accent" height={6} />
          </MCard>
        </div>

        {/* Metrics row */}
        <div style={{ padding: '0 16px 16px', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
          <MetricMini label="Inicio" value="10 Feb" />
          <MetricMini label="Fin" value="5 Abr" warn />
          <MetricMini label="Equipo" value="10 pers" />
        </div>

        <div style={{ padding: '0 16px 16px' }}>
          <MCard padding={14}>
            <div style={{ fontSize: 11, fontFamily: 'var(--font-mono)', color: 'var(--color-ink-3)', textTransform: 'uppercase', letterSpacing: 0.7, fontWeight: 600, marginBottom: 6 }}>Responsable</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <MAvatar name="Martín Pérez" size={36} />
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14, fontWeight: 600 }}>Martín Pérez</div>
                <div style={{ fontSize: 12, color: 'var(--color-ink-3)' }}>Oficial · Mampostería + Revoques</div>
              </div>
              <button style={{ padding: '8px 12px', background: 'var(--color-bg-sunken)', border: '1px solid var(--color-line)', borderRadius: 999, fontSize: 12.5, fontWeight: 600, color: 'var(--color-ink-2)' }}>Mensaje</button>
            </div>
          </MCard>
        </div>

        {/* Tabs — same Qb::TabBar design used en el web (icon + label + count) */}
        <div style={{ padding: '0 16px 8px' }}>
          <div style={{ display: 'flex', gap: 18, borderBottom: '1px solid var(--color-line)', overflowX: 'auto', scrollbarWidth: 'none' }}>
            <Tab icon="materials" label="Materiales" count={2} active />
            <Tab icon="money" label="Gastos" count={3} />
            <Tab icon="note" label="Notas" count={1} />
            <Tab icon="doc" label="Docs" count={3} />
            <Tab icon="image" label="Fotos" count={24} />
          </div>
        </div>

        {/* Tab content: Materiales */}
        <div style={{ padding: '8px 16px 14px' }}>
          <MCard padding={0}>
            <MRow icon="materials" iconBg="color-mix(in oklab, var(--color-accent) 14%, transparent)" title="Ladrillos y morteros · Muros interiores" subtitle="9 ítems · M. Pérez · Aprobada" value="$ 5.2M" />
            <MRow icon="materials" iconBg="color-mix(in oklab, var(--color-warn) 14%, transparent)" title="Ladrillos vistos · Fachada sur" subtitle="5 ítems · En revisión" value="$ 2.2M" isLast />
          </MCard>
        </div>

        <div style={{ padding: '0 16px 16px' }}>
          <MButton variant="secondary" full icon="plus" size="md">Vincular lista de materiales</MButton>
        </div>

        <div style={{ height: 110 }} />
      </div>

      {/* Bottom action bar */}
      <div style={{
        position: 'sticky', bottom: 24, padding: '12px 16px',
        background: 'color-mix(in oklab, var(--color-bg) 90%, transparent)',
        backdropFilter: 'blur(20px) saturate(180%)',
        WebkitBackdropFilter: 'blur(20px) saturate(180%)',
        borderTop: '0.5px solid var(--color-line)',
        display: 'flex', gap: 8
      }}>
        <button style={{
          width: 44, height: 44, borderRadius: 999, background: 'var(--color-bg-raised)',
          border: '1px solid color-mix(in oklab, var(--color-bad) 30%, var(--color-line))',
          color: 'var(--color-bad)', display: 'flex', alignItems: 'center', justifyContent: 'center'
        }}><MIcon name="x" size={18} /></button>
        <MButton variant="secondary" size="md" style={{ flex: 1 }}>Editar</MButton>
        <MButton variant="primary" size="md" icon="check" style={{ flex: 1.4 }}>Completar</MButton>
      </div>
    </div>);

}

function MetricMini({ label, value, warn }) {
  return (
    <MCard padding={12} style={{ textAlign: 'center' }}>
      <div style={{ fontSize: 10.5, fontFamily: 'var(--font-mono)', color: 'var(--color-ink-3)', textTransform: 'uppercase', letterSpacing: 0.7, fontWeight: 600 }}>{label}</div>
      <div className="mono tnum" style={{ fontSize: 15, fontWeight: 700, marginTop: 4, color: warn ? 'var(--color-warn)' : 'var(--color-ink)' }}>{value}</div>
    </MCard>);

}

// Tab component — matches the web `Qb::TabBarComponent` pattern:
// icon + label + small count, underline accent on active, monospace count.
function Tab({ icon, label, count, active }) {
  return (
    <button style={{
      padding: '10px 2px', border: 'none', background: 'transparent',
      borderBottom: `2px solid ${active ? 'var(--color-accent)' : 'transparent'}`,
      color: active ? 'var(--color-accent)' : 'var(--color-ink-3)',
      fontWeight: active ? 600 : 500, fontSize: 13.5,
      marginBottom: -1, display: 'inline-flex', alignItems: 'center', gap: 6,
      whiteSpace: 'nowrap', letterSpacing: -0.1
    }}>
      {icon && <MIcon name={icon} size={14} stroke={active ? 2 : 1.8} />}
      {label}
      {count != null &&
      <span className="mono tnum" style={{
        fontSize: 11, fontWeight: 600,
        color: active ? 'var(--color-accent)' : 'var(--color-ink-4)',
        marginLeft: 1
      }}>{count}</span>
      }
    </button>);

}

// ============================================================
// 12. New stage — modal (bottom sheet)
// ============================================================
function ScreenNewStageModal() {
  return (
    <div className="m-screen" style={{ background: 'rgba(0,0,0,0.42)', position: 'relative' }}>
      {/* Dimmed background hint */}
      <div style={{ padding: '20px 16px', opacity: 0.4, color: 'var(--color-bg)' }}>
        <div style={{ fontSize: 11, fontFamily: 'var(--font-mono)', letterSpacing: 0.8, marginBottom: 8 }}>PRJ-042 · TORRE AURORA</div>
        <div style={{ fontSize: 24, fontWeight: 700 }}>Planificación</div>
      </div>

      <div style={{ flex: 1 }} />

      {/* Sheet */}
      <div style={{
        background: 'var(--color-bg)', borderTopLeftRadius: 24, borderTopRightRadius: 24,
        boxShadow: '0 -8px 30px rgba(0,0,0,0.18)',
        padding: '12px 0 28px', display: 'flex', flexDirection: 'column',
        maxHeight: '80%'
      }}>
        <div style={{ width: 38, height: 5, borderRadius: 5, background: 'var(--color-line-2)', alignSelf: 'center', marginBottom: 14 }} />
        <div style={{ padding: '0 20px 14px', display: 'flex', alignItems: 'center' }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11, fontFamily: 'var(--font-mono)', color: 'var(--color-ink-3)', textTransform: 'uppercase', letterSpacing: 0.7, fontWeight: 600 }}>Nueva etapa</div>
            <h2 style={{ margin: '2px 0 0', fontSize: 22, fontWeight: 700, letterSpacing: -0.4 }}>Crear etapa</h2>
          </div>
          <button style={{ width: 32, height: 32, borderRadius: 999, background: 'var(--color-bg-sunken)', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <MIcon name="x" size={17} color="var(--color-ink-2)" />
          </button>
        </div>

        <div style={{ overflow: 'auto', padding: '4px 16px 0' }}>
          <MFormGroup title="Datos">
            <MFormRow label="Etapa padre" value="— Etapa raíz —" picker placeholder="Elegir etapa padre"/>
            <MFormRow label="Nombre" value="Revoque grueso exterior" placeholder="Ej: Revoque grueso exterior" required/>
            <MFormRow label="Descripción" textarea value="Revoque grueso 1:3 y fino con cemento blanco sobre fachadas norte y sur." placeholder="Detalles, tareas, notas técnicas…"/>
          </MFormGroup>

          <MFormGroup title="Cronograma">
            <MFormRow label="Inicio" value="10 Abr 2026" picker trailing={<MIcon name="calendar" size={16} color="var(--color-ink-3)"/>}/>
            <MFormRow label="Fin"    value="20 May 2026" picker trailing={<MIcon name="calendar" size={16} color="var(--color-ink-3)"/>}/>
          </MFormGroup>

          <MFormGroup title="Asignación" footnote="El responsable recibirá una notificación al guardar.">
            <MFormRow label="Responsable" value="M. Pérez" picker/>
          </MFormGroup>
        </div>

        <div style={{ padding: '16px 20px 0', display: 'flex', gap: 10 }}>
          <MButton variant="secondary" size="md" style={{ flex: 1 }}>Cancelar</MButton>
          <MButton variant="primary" size="md" icon="check" style={{ flex: 1.4 }}>Crear etapa</MButton>
        </div>
      </div>
    </div>);

}

// ============================================================
// 13. Apply template — modal sheet
// ============================================================
function ScreenTemplateModal() {
  return (
    <div className="m-screen" style={{ background: 'rgba(0,0,0,0.42)' }}>
      <div style={{ flex: 1 }} />
      <div style={{ background: 'var(--color-bg)', borderTopLeftRadius: 24, borderTopRightRadius: 24, padding: '12px 0 28px', maxHeight: '88%', display: 'flex', flexDirection: 'column' }}>
        <div style={{ width: 38, height: 5, borderRadius: 5, background: 'var(--color-line-2)', alignSelf: 'center', marginBottom: 14 }} />
        <div style={{ padding: '0 20px 8px' }}>
          <h2 style={{ margin: 0, fontSize: 22, fontWeight: 700, letterSpacing: -0.4 }}>Plantilla de etapas</h2>
          <p style={{ margin: '4px 0 0', fontSize: 13.5, color: 'var(--color-ink-3)', lineHeight: 1.4 }}>Creará las etapas que no existan todavía. Las existentes se mantienen sin cambios.</p>
        </div>

        <div style={{ overflow: 'auto', padding: '12px 20px 0', display: 'flex', flexDirection: 'column', gap: 10 }}>
          {[
          { n: 1, name: 'Proyecto y gestión', desc: 'Definición técnica y administrativa', subs: ['Estudios preliminares', 'Ante proyecto', 'Proyecto (municipal)', 'Documentación y permisos', '3D y visualizaciones', 'Presentación conforme a obra'] },
          { n: 2, name: 'Dirección de obra', desc: 'Coordinación diaria, planos ejecutivos', subs: ['Plan de trabajo', 'Planos ejecutivos por rubros', 'Inspecciones'] },
          { n: 3, name: 'Administración', desc: 'Gestión financiera y contratistas', subs: ['Materiales', 'Mano de obra'] }].
          map((t) =>
          <MCard key={t.n} padding={14}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
                <div style={{ width: 30, height: 30, borderRadius: 8, background: 'color-mix(in oklab, var(--color-accent) 14%, transparent)', color: 'var(--color-accent)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'var(--font-mono)', fontWeight: 700, fontSize: 13 }}>{t.n}</div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 14.5, fontWeight: 600 }}>{t.name}</div>
                  <div style={{ fontSize: 11.5, color: 'var(--color-ink-3)' }}>{t.desc}</div>
                </div>
                <span className="mono" style={{ fontSize: 10.5, color: 'var(--color-ink-4)', background: 'var(--color-bg-sunken)', padding: '2px 7px', borderRadius: 4, fontWeight: 600 }}>{t.subs.length} sub</span>
              </div>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
                {t.subs.map((s) => <span key={s} style={{ fontSize: 11.5, padding: '4px 10px', background: 'var(--color-bg-sunken)', borderRadius: 999, color: 'var(--color-ink-2)' }}>{s}</span>)}
              </div>
            </MCard>
          )}
        </div>

        <div style={{ padding: '16px 20px 0', display: 'flex', gap: 10 }}>
          <MButton variant="secondary" size="md" style={{ flex: 1 }}>Cancelar</MButton>
          <MButton variant="primary" size="md" icon="sparkles" style={{ flex: 1.6 }}>Aplicar plantilla</MButton>
        </div>
      </div>
    </div>);

}

Object.assign(window, {
  ScreenProjectOverview, ScreenStages, ScreenStageDetail,
  ScreenNewStageModal, ScreenTemplateModal
});