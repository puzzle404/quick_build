// Mobile screens · Part 3 — Materials + Blueprints + Team + Docs + modals + New project

// ============================================================
// 14. Materials — Lists of materials (grid of cards)
// ============================================================
function ScreenMaterials() {
  return (
    <div className="m-screen">
      <MNavBar back title="Torre Aurora" right={
        <button style={{background:'transparent', border:'none'}}><MIcon name="plus" size={22} color="var(--color-accent)"/></button>
      }/>

      <div style={{padding:'4px 20px 8px'}}>
        <h1 style={{margin:0, fontSize:24, fontWeight:700, letterSpacing:-0.5}}>Materiales</h1>
        <div style={{fontSize:13, color:'var(--color-ink-3)', marginTop:4}}>9 listas · 5 aprobadas · 2 en revisión · $ 46M total</div>
      </div>

      {/* Source action sheet */}
      <div style={{padding:'8px 16px 12px'}}>
        <div style={{display:'flex', gap:8, overflowX:'auto', scrollbarWidth:'none'}}>
          <SourceChip icon="edit" label="Manual"/>
          <SourceChip icon="doc"  label="PDF" hint="IA"/>
          <SourceChip icon="upload" label="Excel"/>
          <SourceChip icon="sparkles" label="Generar con IA" accent/>
        </div>
      </div>

      {/* Filter tabs — underline (new design system) */}
      <MTabs value="all" options={[
        { k:'all',       l:'Todos',       c:9, active:true },
        { k:'approved',  l:'Aprobadas',   c:5 },
        { k:'review',    l:'En revisión', c:2 },
        { k:'draft',     l:'Borradores',  c:2 },
      ]}/>

      <div style={{flex:1, overflow:'auto', padding:'8px 16px 8px'}}>
        <div style={{display:'flex', flexDirection:'column', gap:10}}>
          <MaterialListCard name="Hierros · Columnas y losas 1°–3°" stage="Estructura" status="approved" source="pdf_upload" items={12} total="$ 12.6M" author="IA Blueprint" date="10 Dic"/>
          <MaterialListCard name="Ladrillos y morteros · Muros" stage="Mampostería" status="approved" source="manual" items={9} total="$ 5.2M" author="M. Pérez" date="2 Feb"/>
          <MaterialListCard name="Ladrillos vistos · Fachada sur" stage="Mampostería" status="ready_for_review" source="manual" items={5} total="$ 2.2M" author="M. Pérez" date="18 Mar" notes="3 cotizaciones pendientes"/>
          <MaterialListCard name="Cañerías PVC y accesorios" stage="Sanitarias" status="approved" source="excel_upload" items={18} total="$ 3.4M" author="J. Silva" date="22 Feb"/>
          <MaterialListCard name="Cemento, cal y arena · Revoques" stage="Revoques" status="draft" source="manual" items={3} total="$ 860k" author="M. Fernández" date="15 Abr" privateList/>
        </div>
        <div style={{height: 80}}/>
      </div>
    </div>
  );
}

function SourceChip({ icon, label, hint, accent }) {
  return (
    <button style={{
      padding:'10px 14px', borderRadius:12,
      background: accent ? 'color-mix(in oklab, var(--color-accent) 12%, transparent)' : 'var(--color-bg-raised)',
      border: `1px solid ${accent ? 'color-mix(in oklab, var(--color-accent) 30%, var(--color-line))' : 'var(--color-line)'}`,
      color: accent ? 'var(--color-accent)' : 'var(--color-ink-2)',
      display:'inline-flex', alignItems:'center', gap:8, whiteSpace:'nowrap',
    }}>
      <MIcon name={icon} size={16}/>
      <span style={{fontSize:13.5, fontWeight:600}}>{label}</span>
      {hint && <span style={{fontSize:9.5, fontFamily:'var(--font-mono)', fontWeight:700, padding:'2px 5px', background: accent ? 'rgba(255,255,255,0.4)' : 'var(--color-accent)', color: accent ? 'var(--color-accent)' : 'var(--color-accent-ink)', borderRadius:3, letterSpacing:0.4}}>{hint}</span>}
    </button>
  );
}

function MaterialListCard({ name, stage, status, source, items, total, author, date, notes, privateList }) {
  const sMap = {
    approved:         { tone:'ok',    label:'Aprobada' },
    ready_for_review: { tone:'warn',  label:'En revisión' },
    draft:            { tone:'muted', label:'Borrador' },
  };
  const sLabel = sMap[status];
  const srcIcon = { manual:'edit', pdf_upload:'doc', excel_upload:'upload' }[source];
  const srcLabel = { manual:'Manual', pdf_upload:'PDF', excel_upload:'Excel' }[source];
  return (
    <MCard padding={14}>
      <div style={{display:'flex', alignItems:'flex-start', gap:12}}>
        <div style={{width:36, height:36, borderRadius:10, background: source==='pdf_upload' ? 'color-mix(in oklab, var(--color-accent) 14%, transparent)' : 'var(--color-bg-sunken)', color: source==='pdf_upload' ? 'var(--color-accent)' : 'var(--color-ink-2)', display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0}}>
          <MIcon name={srcIcon} size={17}/>
        </div>
        <div style={{flex:1, minWidth:0}}>
          <div style={{display:'flex', alignItems:'center', gap:5, flexWrap:'wrap', marginBottom:4}}>
            <MPill tone={sLabel.tone} dense>{sLabel.label}</MPill>
            {privateList && <MPill tone="muted" dense>Privada</MPill>}
            {source !== 'manual' && <span style={{fontSize:10, fontFamily:'var(--font-mono)', color:'var(--color-ink-4)', fontWeight:600}}>{srcLabel}</span>}
          </div>
          <div style={{fontSize:14.5, fontWeight:600, lineHeight:1.3}}>{name}</div>
          <div style={{fontSize:12, color:'var(--color-ink-3)', marginTop:3, display:'inline-flex', alignItems:'center', gap:4}}>
            <MIcon name="stages" size={11}/> {stage}
          </div>
        </div>
      </div>

      {notes && (
        <div style={{marginTop:10, padding:'8px 10px', background:'var(--color-bg-sunken)', borderLeft:'2px solid var(--color-warn)', borderRadius:5, fontSize:11.5, color:'var(--color-ink-2)'}}>
          {notes}
        </div>
      )}

      <div style={{display:'flex', alignItems:'center', justifyContent:'space-between', marginTop:12, paddingTop:10, borderTop:'1px solid var(--color-line)'}}>
        <div style={{display:'flex', alignItems:'center', gap:8}}>
          <MAvatar name={author} size={20}/>
          <div>
            <div style={{fontSize:11.5, color:'var(--color-ink-2)', fontWeight:500}}>{author}</div>
            <div className="mono" style={{fontSize:10, color:'var(--color-ink-4)'}}>{date}</div>
          </div>
        </div>
        <div style={{textAlign:'right'}}>
          <div className="mono tnum" style={{fontSize:16, fontWeight:700, letterSpacing:-0.3}}>{total}</div>
          <div style={{fontSize:11, color:'var(--color-ink-3)'}}>{items} ítems</div>
        </div>
      </div>
    </MCard>
  );
}

// ============================================================
// 15. Material list detail (items list)
// ============================================================
function ScreenMaterialListDetail() {
  return (
    <div className="m-screen">
      <MNavBar back title="" right={
        <button style={{background:'transparent', border:'none'}}><MIcon name="more" size={22} color="var(--color-ink-2)"/></button>
      }/>

      <div style={{padding:'4px 20px 14px'}}>
        <div style={{display:'flex', alignItems:'center', gap:8, marginBottom:10}}>
          <MPill tone="ok" dense>Aprobada</MPill>
          <MPill tone="muted" dense>Pública</MPill>
          <span className="mono" style={{fontSize:10.5, color:'var(--color-ink-4)', fontWeight:600}}>PDF · IA</span>
        </div>
        <h1 style={{margin:'0 0 6px', fontSize:22, fontWeight:700, letterSpacing:-0.4, lineHeight:1.2}}>Hierros · Columnas y losas 1°–3°</h1>
        <div style={{fontSize:13, color:'var(--color-ink-3)', display:'inline-flex', alignItems:'center', gap:4}}>
          <MIcon name="stages" size={12}/> Estructura · PRJ-042
        </div>
      </div>

      {/* Metadata strip */}
      <div style={{padding:'0 16px 14px', display:'grid', gridTemplateColumns:'1fr 1fr', gap:8}}>
        <MCard padding={10}>
          <div style={{fontSize:10.5, fontFamily:'var(--font-mono)', color:'var(--color-ink-3)', textTransform:'uppercase', letterSpacing:0.7, fontWeight:600}}>Autor</div>
          <div style={{display:'flex', alignItems:'center', gap:6, marginTop:3}}>
            <MAvatar name="IA Blueprint" size={18}/>
            <div style={{fontSize:13, fontWeight:500}}>IA Blueprint</div>
          </div>
          <div style={{fontSize:10.5, color:'var(--color-ink-4)', marginTop:2}}>Aprob. 15 Dic</div>
        </MCard>
        <MCard padding={10}>
          <div style={{fontSize:10.5, fontFamily:'var(--font-mono)', color:'var(--color-ink-3)', textTransform:'uppercase', letterSpacing:0.7, fontWeight:600}}>Total estimado</div>
          <div className="mono tnum" style={{fontSize:18, fontWeight:700, marginTop:3, letterSpacing:-0.3}}>$ 12.6M</div>
          <div style={{fontSize:11, color:'var(--color-ink-3)', marginTop:1}}>12 ítems</div>
        </MCard>
      </div>

      <div style={{flex:1, overflow:'auto'}}>
        <MSection title="Ítems · 12">
          <MCard padding={0}>
            <ItemRow num={1} name="Hierro ø6 12m ADN 420" sub="Estribos columnas y vigas" qty="180" unit="barra" total="$ 1.1M"/>
            <ItemRow num={2} name="Hierro ø8 12m ADN 420" sub="Estribos principales" qty="640" unit="barra" total="$ 5.8M"/>
            <ItemRow num={3} name="Hierro ø10 12m ADN 420" sub="Armado de losas" qty="320" unit="barra" total="$ 4.5M"/>
            <ItemRow num={4} name="Hierro ø12 12m ADN 420" sub="Columnas principales" qty="420" unit="barra" total="$ 8.4M"/>
            <ItemRow num={5} name="Hierro ø16 12m ADN 420" sub="Columnas de borde" qty="140" unit="barra" total="$ 5.2M"/>
            <ItemRow num={6} name="Hierro ø20 12m ADN 420" sub="Vigas principales · Revisar con calculista" qty="68" unit="barra" total="$ 3.9M" warn/>
            <ItemRow num={7} name="Alambre recocido Nº14" sub="Atadura de armaduras" qty="40" unit="kg" total="$ 152k" isLast/>
          </MCard>
        </MSection>

        <div style={{padding:'8px 16px 16px'}}>
          <MButton variant="secondary" full icon="plus" size="md">Agregar ítem</MButton>
        </div>

        <div style={{height: 110}}/>
      </div>

      {/* Bottom bar with totals */}
      <div style={{
        padding:'10px 20px 28px',
        background:'color-mix(in oklab, var(--color-bg) 92%, transparent)',
        backdropFilter:'blur(20px) saturate(180%)',
        WebkitBackdropFilter:'blur(20px) saturate(180%)',
        borderTop:'0.5px solid var(--color-line)',
        display:'flex', alignItems:'center', gap:10,
      }}>
        <div style={{flex:1}}>
          <div style={{fontSize:10.5, fontFamily:'var(--font-mono)', color:'var(--color-ink-3)', textTransform:'uppercase', letterSpacing:0.6, fontWeight:600}}>Total estimado</div>
          <div className="mono tnum" style={{fontSize:18, fontWeight:700, letterSpacing:-0.3}}>$ 12.640.450</div>
        </div>
        <MButton variant="primary" size="md" icon="download">Exportar</MButton>
      </div>
    </div>
  );
}

function ItemRow({ num, name, sub, qty, unit, total, warn, isLast }) {
  return (
    <div style={{display:'flex', alignItems:'flex-start', gap:10, padding:'12px 14px', borderBottom: isLast ? 'none' : '1px solid var(--color-line)'}}>
      <span className="mono tnum" style={{fontSize:10.5, color:'var(--color-ink-4)', width:20, paddingTop:2, fontWeight:600}}>{String(num).padStart(2,'0')}</span>
      <div style={{flex:1, minWidth:0}}>
        <div style={{fontSize:14, fontWeight:600, color:'var(--color-ink)'}}>{name}</div>
        {sub && <div style={{fontSize:11.5, color: warn ? 'var(--color-warn)' : 'var(--color-ink-3)', marginTop:2, display:'inline-flex', alignItems:'center', gap:3}}>
          {warn && <MIcon name="bell" size={10}/>}{sub}
        </div>}
        <div className="mono tnum" style={{fontSize:11, color:'var(--color-ink-3)', marginTop:4}}>{qty} {unit}</div>
      </div>
      <div className="mono tnum" style={{fontSize:14, fontWeight:700, color:'var(--color-ink)'}}>{total}</div>
    </div>
  );
}

// ============================================================
// 16. New material list — bottom sheet
// ============================================================
function ScreenNewMaterialListModal() {
  return (
    <div className="m-screen" style={{background:'rgba(0,0,0,0.42)'}}>
      <div style={{flex:1}}/>
      <div style={{background:'var(--color-bg)', borderTopLeftRadius:24, borderTopRightRadius:24, padding:'12px 0 28px', maxHeight:'88%', display:'flex', flexDirection:'column'}}>
        <div style={{width:38, height:5, borderRadius:5, background:'var(--color-line-2)', alignSelf:'center', marginBottom:14}}/>
        <div style={{padding:'0 20px 12px'}}>
          <h2 style={{margin:0, fontSize:22, fontWeight:700, letterSpacing:-0.4}}>Nueva lista de materiales</h2>
        </div>

        <div style={{overflow:'auto', padding:'0 16px'}}>
          <MFormGroup title="Datos de la lista">
            <MFormRow label="Nombre" value="Hierros · Losas 4°–6°" required placeholder="Ej: Hierros · Losas 4°–6°"/>
            <MFormRow label="Etapa asociada" value="Estructura" picker/>
            <MFormRow label="Notas" textarea value="Cargada vía análisis IA del plano A-04 rev.1." placeholder="Contexto para tu equipo…" helper="Opcional · visible solo si publicás la lista."/>
          </MFormGroup>

          <MFormGroup title="Origen de los ítems">
            <div style={{padding:'12px 14px'}}>
              <div style={{display:'grid', gridTemplateColumns:'repeat(3, 1fr)', gap:8}}>
                <SourcePick icon="edit" label="Manual" hint="Uno por uno"/>
                <SourcePick icon="doc" label="PDF" hint="IA detecta" active/>
                <SourcePick icon="upload" label="Excel" hint="Mapear cols"/>
              </div>
            </div>
          </MFormGroup>

          <MFormGroup title="Visibilidad">
            <MFormToggleRow label="Publicar al equipo" sub="Los miembros del proyecto pueden ver y presupuestar." defaultChecked/>
          </MFormGroup>
        </div>

        <div style={{padding:'16px 20px 0', display:'flex', gap:10}}>
          <MButton variant="secondary" size="md" style={{flex:1}}>Cancelar</MButton>
          <MButton variant="primary" size="md" iconRight="arrow-right" style={{flex:1.4}}>Crear y subir PDF</MButton>
        </div>
      </div>
    </div>
  );
}

function SourcePick({ icon, label, hint, active }) {
  return (
    <button style={{
      padding:10, borderRadius:12,
      background: active ? 'color-mix(in oklab, var(--color-accent) 10%, transparent)' : 'var(--color-bg-raised)',
      border: active ? '1.5px solid var(--color-accent)' : '1px solid var(--color-line)',
      color: active ? 'var(--color-accent)' : 'var(--color-ink-2)',
      display:'flex', flexDirection:'column', gap:4, alignItems:'flex-start',
    }}>
      <MIcon name={icon} size={18}/>
      <span style={{fontSize:13, fontWeight:700}}>{label}</span>
      <span style={{fontSize:10.5, color: active ? 'var(--color-accent)' : 'var(--color-ink-3)', fontWeight:500}}>{hint}</span>
    </button>
  );
}

// ============================================================
// 17. Blueprints — AI workspace
// ============================================================
function ScreenBlueprints() {
  return (
    <div className="m-screen">
      <MNavBar back title="Planos · IA" right={
        <button style={{background:'transparent', border:'none'}}><MIcon name="plus" size={22} color="var(--color-accent)"/></button>
      }/>

      <div style={{padding:'4px 20px 12px'}}>
        <h1 style={{margin:0, fontSize:22, fontWeight:700, letterSpacing:-0.4}}>Análisis automático</h1>
        <div style={{fontSize:13, color:'var(--color-ink-3)', marginTop:3}}>3 listos · 1 procesando · 1 en cola</div>
      </div>

      {/* Big upload card */}
      <div style={{padding:'0 16px 16px'}}>
        <MCard padding={18} style={{background:'linear-gradient(135deg, oklch(96% 0.05 255) 0%, var(--color-bg-raised) 100%)', border:'1.5px dashed color-mix(in oklab, var(--color-accent) 40%, var(--color-line))'}}>
          <div style={{display:'flex', alignItems:'center', gap:14}}>
            <div style={{width:48, height:48, borderRadius:14, background:'color-mix(in oklab, var(--color-accent) 14%, transparent)', color:'var(--color-accent)', display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0}}>
              <MIcon name="sparkles" size={24}/>
            </div>
            <div style={{flex:1}}>
              <div style={{fontSize:14.5, fontWeight:700}}>Subir plano para análisis</div>
              <div style={{fontSize:11.5, color:'var(--color-ink-3)', marginTop:2}}>PDF o DWG · La IA detecta ambientes, muros y cómputos.</div>
            </div>
            <MIcon name="upload" size={20} color="var(--color-accent)"/>
          </div>
        </MCard>
      </div>

      <div style={{flex:1, overflow:'auto'}}>
        <MSection title="Análisis en curso">
          <MCard padding={14}>
            <div style={{display:'flex', alignItems:'center', gap:12, marginBottom:10}}>
              <div style={{width:36, height:36, borderRadius:8, background:'var(--color-bg-sunken)', display:'flex', alignItems:'center', justifyContent:'center', position:'relative'}}>
                <MIcon name="blueprint" size={17} color="var(--color-accent)"/>
                <span style={{position:'absolute', top:-3, right:-3, width:12, height:12, borderRadius:999, background:'var(--color-accent)', border:'2px solid var(--color-bg-raised)'}}/>
              </div>
              <div style={{flex:1}}>
                <div style={{fontSize:14, fontWeight:600}}>A-04 Losa 3° rev.1</div>
                <div style={{fontSize:11.5, color:'var(--color-ink-3)'}}>Procesando cómputo métrico…</div>
              </div>
              <MPill tone="accent" dense>72%</MPill>
            </div>
            <MBar value={72} tone="accent" height={4}/>
          </MCard>
        </MSection>

        <MSection title="Completados · 3">
          <MCard padding={0}>
            <BlueprintRow code="A-01" name="Planta baja rev.3" date="14 Dic" area="342 m²" rooms={8} confidence={96}/>
            <BlueprintRow code="A-02" name="Planta tipo rev.2" date="4 Ene" area="298 m²" rooms={6} confidence={92} warn/>
            <BlueprintRow code="A-03" name="Losa 2° rev.1" date="22 Ene" area="298 m²" rooms="—" confidence={88} structural isLast/>
          </MCard>
        </MSection>

        <MSection title="En cola · 1">
          <MCard padding={0}>
            <MRow icon="blueprint" iconBg="var(--color-bg-sunken)" title="A-05 Corte longitudinal" subtitle="En cola — empieza al terminar A-04" value="—" isLast/>
          </MCard>
        </MSection>

        <div style={{height: 80}}/>
      </div>
    </div>
  );
}

function BlueprintRow({ code, name, date, area, rooms, confidence, structural, warn, isLast }) {
  return (
    <div style={{display:'flex', alignItems:'flex-start', gap:12, padding:'12px 14px', borderBottom: isLast ? 'none' : '1px solid var(--color-line)'}}>
      <div style={{width:36, height:36, borderRadius:8, background:'color-mix(in oklab, var(--color-accent) 12%, transparent)', color:'var(--color-accent)', display:'flex', alignItems:'center', justifyContent:'center', flexShrink:0}}>
        <MIcon name="blueprint" size={17}/>
      </div>
      <div style={{flex:1, minWidth:0}}>
        <div style={{display:'flex', alignItems:'center', gap:6, marginBottom:3}}>
          <span className="mono" style={{fontSize:10.5, color:'var(--color-ink-3)', fontWeight:700}}>{code}</span>
          <MPill tone="ok" dense>Listo</MPill>
          {warn && <MPill tone="warn" dense>revisar</MPill>}
        </div>
        <div style={{fontSize:14, fontWeight:600}}>{name}</div>
        <div className="mono" style={{fontSize:11, color:'var(--color-ink-3)', marginTop:3, display:'flex', flexWrap:'wrap', gap:'2px 10px'}}>
          <span>{date}</span><span>{area}</span>{rooms !== '—' && <span>{rooms} amb.</span>}{structural && <span>estructural</span>}<span>{confidence}% conf.</span>
        </div>
      </div>
      <MIcon name="chev-right" size={16} color="var(--color-ink-4)"/>
    </div>
  );
}

// ============================================================
// 18. Team — people + attendance
// ============================================================
function ScreenTeam() {
  return (
    <div className="m-screen">
      <MNavBar back title="Torre Aurora" right={
        <button style={{background:'transparent', border:'none'}}><MIcon name="plus" size={22} color="var(--color-accent)"/></button>
      }/>

      <div style={{padding:'4px 20px 12px'}}>
        <h1 style={{margin:0, fontSize:24, fontWeight:700, letterSpacing:-0.5}}>Equipo</h1>
        <div style={{fontSize:13, color:'var(--color-ink-3)', marginTop:4}}>22 personas · 91% asistencia promedio</div>
      </div>

      {/* Today bar (attendance) */}
      <div style={{padding:'0 16px 16px'}}>
        <MCard padding={14}>
          <div style={{display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom:10}}>
            <div>
              <div style={{fontSize:11, fontFamily:'var(--font-mono)', color:'var(--color-ink-3)', textTransform:'uppercase', letterSpacing:0.7, fontWeight:600}}>Hoy · 17 Abr</div>
              <div style={{fontSize:13.5, fontWeight:600, marginTop:2}}>20 presentes · 2 ausentes</div>
            </div>
            <MButton variant="primary" size="sm" icon="check">Tomar asistencia</MButton>
          </div>
          <div style={{display:'flex', gap:4}}>
            {Array.from({length:22}).map((_,i) => (
              <div key={i} style={{flex:1, height:32, borderRadius:4, background: i < 20 ? 'var(--color-ok)' : 'var(--color-bg-sunken)', opacity: i < 20 ? (0.5 + (i % 5) * 0.1) : 0.5}}/>
            ))}
          </div>
        </MCard>
      </div>

      {/* Role tabs — underline (new design system) */}
      <MTabs value="all" options={[
        { k:'all',          l:'Todos',        c:22, active:true },
        { k:'capataces',    l:'Capataces',    c:2 },
        { k:'oficiales',    l:'Oficiales',    c:8 },
        { k:'ayudantes',    l:'Ayudantes',    c:6 },
        { k:'instaladores', l:'Instaladores', c:4 },
        { k:'otros',        l:'Otros',        c:2 },
      ]}/>

      <div style={{flex:1, overflow:'auto', padding:'8px 16px 8px'}}>
        <MCard padding={0}>
          <PersonRow name="Rodrigo Díaz" role="Capataz" trade="Mov. de suelos" attendance={98} rate="$ 5.200/h" present/>
          <PersonRow name="Federico López" role="Encargado" trade="Estructura" attendance={95} rate="$ 4.800/h" present/>
          <PersonRow name="Martín Pérez" role="Oficial" trade="Mampostería" attendance={92} rate="$ 3.900/h" present/>
          <PersonRow name="Javier Silva" role="Instalador" trade="Sanit. + eléc." attendance={88} rate="$ 5.600/h" present/>
          <PersonRow name="Agustín Gómez" role="Oficial" trade="Pisos · carpint." attendance={100} rate="$ 4.200/h" present/>
          <PersonRow name="Carla Ruiz" role="Oficial" trade="Pintura" attendance={90} rate="$ 3.800/h" leave/>
          <PersonRow name="Santiago Costa" role="Ayudante" trade="General" attendance={85} rate="$ 2.600/h" present/>
          <PersonRow name="Nicolás Vega" role="Ayudante" trade="General" attendance={75} rate="$ 2.600/h" absent isLast/>
        </MCard>
        <div style={{height: 80}}/>
      </div>
    </div>
  );
}

function PersonRow({ name, role, trade, attendance, rate, present, absent, leave, isLast }) {
  return (
    <div style={{display:'flex', alignItems:'center', gap:12, padding:'12px 14px', borderBottom: isLast ? 'none' : '1px solid var(--color-line)'}}>
      <div style={{position:'relative', flexShrink:0}}>
        <MAvatar name={name} size={40}/>
        {(present || absent || leave) && (
          <span style={{position:'absolute', bottom:-1, right:-1, width:12, height:12, borderRadius:999, background: present ? 'var(--color-ok)' : absent ? 'var(--color-bad)' : 'var(--color-warn)', border:'2px solid var(--color-bg-raised)'}}/>
        )}
      </div>
      <div style={{flex:1, minWidth:0}}>
        <div style={{fontSize:14.5, fontWeight:600, color:'var(--color-ink)'}}>{name}</div>
        <div style={{fontSize:12, color:'var(--color-ink-3)'}}>{role} · {trade}</div>
      </div>
      <div style={{textAlign:'right'}}>
        <div className="mono tnum" style={{fontSize:13, fontWeight:600, color: attendance < 80 ? 'var(--color-bad)' : attendance < 90 ? 'var(--color-warn)' : 'var(--color-ok)'}}>{attendance}%</div>
        <div className="mono" style={{fontSize:10.5, color:'var(--color-ink-4)', marginTop:1}}>{rate}</div>
      </div>
    </div>
  );
}

// ============================================================
// 19. Documents — project library
// ============================================================
function ScreenDocs() {
  return (
    <div className="m-screen">
      <MNavBar back title="Torre Aurora" right={
        <button style={{background:'transparent', border:'none'}}><MIcon name="upload" size={20} color="var(--color-accent)"/></button>
      }/>

      <div style={{padding:'4px 20px 8px'}}>
        <h1 style={{margin:0, fontSize:24, fontWeight:700, letterSpacing:-0.5}}>Documentos</h1>
        <div style={{fontSize:13, color:'var(--color-ink-3)', marginTop:4}}>47 archivos · 5 fijados · 235 MB</div>
      </div>

      {/* Type tabs — underline (new design system) */}
      <MTabs value="all" options={[
        { k:'all',   l:'Todos',  active:true },
        { k:'pdf',   l:'PDF',    c:28 },
        { k:'dwg',   l:'DWG',    c:12 },
        { k:'xls',   l:'XLS',    c:4 },
        { k:'fotos', l:'Fotos',  c:3 },
      ]}/>

      <div style={{flex:1, overflow:'auto'}}>
        <MSection title="Fijados">
          <MCard padding={0}>
            <DocRow type="PDF" name="Contrato marco · Delta S.A." stage="Inicio" date="2 Nov" size="1.4 MB" uploader="M. Fernández" pinned/>
            <DocRow type="DWG" name="Plano A-01 planta baja rev.3" stage="Estructura" date="14 Dic" size="8.2 MB" uploader="F. López" pinned isLast/>
          </MCard>
        </MSection>

        <MSection title="Recientes">
          <MCard padding={0}>
            <DocRow type="PDF" name="Plano A-04 losa 3° rev.1" stage="Estructura" date="28 Ene" size="3.1 MB" uploader="F. López"/>
            <DocRow type="PDF" name="Certificado 1 · avance 18%" stage="Administrativo" date="1 Feb" size="612 KB" uploader="M. Fernández"/>
            <DocRow type="XLS" name="Cómputo métrico hierros" stage="Estructura" date="3 Feb" size="74 KB" uploader="IA Blueprint"/>
            <DocRow type="ZIP" name="Fotos avance hormigonado 3°" stage="Estructura" date="20 Feb" size="42 MB" uploader="R. Díaz"/>
            <DocRow type="PDF" name="Cotización hierros · Acindar" stage="Estructura" date="22 Feb" size="380 KB" uploader="M. Fernández" isLast/>
          </MCard>
        </MSection>

        <div style={{height: 80}}/>
      </div>
    </div>
  );
}

function DocRow({ type, name, stage, date, size, uploader, pinned, isLast }) {
  const colors = {
    PDF: 'oklch(55% 0.18 25)',
    DWG: 'oklch(55% 0.22 255)',
    XLS: 'oklch(55% 0.16 145)',
    ZIP: 'oklch(55% 0.15 80)',
  };
  return (
    <div style={{display:'flex', alignItems:'center', gap:12, padding:'12px 14px', borderBottom: isLast ? 'none' : '1px solid var(--color-line)'}}>
      <div style={{width:40, height:40, borderRadius:8, background:'var(--color-bg-sunken)', display:'flex', alignItems:'center', justifyContent:'center', fontSize:10, fontFamily:'var(--font-mono)', fontWeight:800, color: colors[type] || 'var(--color-ink-3)', flexShrink:0, letterSpacing:0.5}}>{type}</div>
      <div style={{flex:1, minWidth:0}}>
        <div style={{display:'flex', alignItems:'center', gap:5}}>
          {pinned && <MIcon name="pin" size={12} color="var(--color-accent)"/>}
          <div style={{fontSize:14, fontWeight:600, color:'var(--color-ink)', whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis'}}>{name}</div>
        </div>
        <div className="mono" style={{fontSize:11, color:'var(--color-ink-3)', marginTop:2}}>{stage} · {date} · {size}</div>
        <div style={{fontSize:11, color:'var(--color-ink-4)', marginTop:1}}>{uploader}</div>
      </div>
      <MIcon name="more" size={18} color="var(--color-ink-4)"/>
    </div>
  );
}

// ============================================================
// 20. New project — modal sheet (compact wizard step 1/4)
// ============================================================
function ScreenNewProject() {
  return (
    <div className="m-screen">
      <MNavBar back title="Nuevo proyecto" right={
        <span style={{fontSize:13, color:'var(--color-ink-3)', fontWeight:500}}>Paso 1 de 4</span>
      }/>

      <div style={{padding:'4px 20px 18px'}}>
        <h1 style={{margin:0, fontSize:24, fontWeight:700, letterSpacing:-0.4, lineHeight:1.2}}>Datos básicos</h1>
        <div style={{fontSize:13.5, color:'var(--color-ink-3)', marginTop:6}}>Empezá con lo esencial. Después agregás equipo y plantilla.</div>
      </div>

      {/* Progress */}
      <div style={{padding:'0 20px 20px', display:'flex', gap:6}}>
        {[1,2,3,4].map(n => (
          <div key={n} style={{flex:1, height:4, borderRadius:2, background: n === 1 ? 'var(--color-accent)' : 'var(--color-line)'}}/>
        ))}
      </div>

      <div style={{flex:1, overflow:'auto', padding:'0 16px'}}>
        <MFormGroup title="Identidad">
          <MFormRow label="Nombre del proyecto" value="Torre Palermo · Edif. Aurora" placeholder="Ej: Torre Palermo" required/>
          <MFormRow label="Cliente / Comitente" value="Inmobiliaria Delta S.A." placeholder="Razón social o persona" required/>
          <MFormRow label="Ubicación" value="Av. Santa Fe 3421, CABA" picker trailing={<MIcon name="map-pin" size={16} color="var(--color-accent)"/>}/>
        </MFormGroup>

        <MFormGroup title="Cronograma y presupuesto">
          <MFormRow label="Fecha de inicio" value="4 Nov 2025" picker trailing={<MIcon name="calendar" size={16} color="var(--color-ink-3)"/>}/>
          <MFormRow label="Entrega estimada" value="18 Ago 2026" picker trailing={<MIcon name="calendar" size={16} color="var(--color-ink-3)"/>}/>
          <MFormAmountRow label="Presupuesto" value="84.500.000"/>
        </MFormGroup>

        <MFormGroup title="Tipo de obra">
          <div style={{padding:'10px 14px'}}>
            <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:8}}>
              {[
                {l:'Obra nueva', a:true},
                {l:'Reforma integral'},
                {l:'Ampliación'},
                {l:'Refuncionalización'},
              ].map(t => (
                <button key={t.l} style={{
                  padding:'12px 14px', borderRadius:12,
                  background: t.a ? 'color-mix(in oklab, var(--color-accent) 10%, transparent)' : 'var(--color-bg-sunken)',
                  border: t.a ? '1.5px solid var(--color-accent)' : '1px solid var(--color-line)',
                  color: t.a ? 'var(--color-accent)' : 'var(--color-ink)',
                  fontSize: 14, fontWeight: 600, textAlign:'left',
                }}>{t.l}</button>
              ))}
            </div>
          </div>
        </MFormGroup>

        <div style={{height: 100}}/>
      </div>

      <div style={{padding:'12px 20px 32px', borderTop:'0.5px solid var(--color-line)', background:'var(--color-bg)'}}>
        <MButton variant="primary" size="lg" full iconRight="arrow-right">Continuar</MButton>
      </div>
    </div>
  );
}

// ============================================================
// 21. Expense modal (registrar gasto)
// ============================================================
function ScreenExpenseModal() {
  return (
    <div className="m-screen" style={{background:'rgba(0,0,0,0.42)'}}>
      <div style={{flex:1}}/>
      <div style={{background:'var(--color-bg)', borderTopLeftRadius:24, borderTopRightRadius:24, padding:'12px 0 28px', display:'flex', flexDirection:'column'}}>
        <div style={{width:38, height:5, borderRadius:5, background:'var(--color-line-2)', alignSelf:'center', marginBottom:14}}/>
        <div style={{padding:'0 20px 12px'}}>
          <div style={{fontSize:11, fontFamily:'var(--font-mono)', color:'var(--color-ink-3)', textTransform:'uppercase', letterSpacing:0.7, fontWeight:600}}>PRJ-042 · Estructura</div>
          <h2 style={{margin:'2px 0 0', fontSize:22, fontWeight:700, letterSpacing:-0.4}}>Registrar gasto</h2>
        </div>

        <div style={{padding:'0 16px', display:'flex', flexDirection:'column'}}>
          <MFormGroup title="Detalles del gasto">
            <MFormAmountRow label="Monto" value="1.420.000" sub="Pesos argentinos"/>
            <MFormRow label="Concepto" value="Compra hierro ø12 + acopio" placeholder="Ej: Compra hierro ø12"/>
            <MFormRow label="Proveedor" value="Acindar" picker/>
            <MFormRow label="Fecha" value="17 Abr 2026" picker trailing={<MIcon name="calendar" size={16} color="var(--color-ink-3)"/>}/>
            <MFormRow label="Forma de pago" value="Transferencia" picker/>
          </MFormGroup>

          <MFormGroup title="Categoría">
            <div style={{padding:'10px 14px', display:'flex', flexWrap:'wrap', gap:6}}>
              {['Materiales','Mano de obra','Servicios','Impuestos','Otros'].map((c, i) => (
                <button key={c} style={{
                  padding:'7px 12px', borderRadius:999,
                  background: i === 0 ? 'color-mix(in oklab, var(--color-accent) 14%, transparent)' : 'var(--color-bg-sunken)',
                  color: i === 0 ? 'var(--color-accent)' : 'var(--color-ink-2)',
                  border: 'none',
                  fontSize:12.5, fontWeight:600,
                }}>{c}</button>
              ))}
            </div>
          </MFormGroup>

          <MFormGroup>
            <button style={{padding:'14px', background:'transparent', border:'none', color:'var(--color-accent)', fontSize:14, fontWeight:600, display:'flex', alignItems:'center', justifyContent:'center', gap:6, width:'100%'}}>
              <MIcon name="upload" size={16}/> Adjuntar comprobante (foto / PDF)
            </button>
          </MFormGroup>
        </div>

        <div style={{padding:'16px 20px 0', display:'flex', gap:10}}>
          <MButton variant="secondary" size="md" style={{flex:1}}>Cancelar</MButton>
          <MButton variant="primary" size="md" icon="check" style={{flex:1.4}}>Guardar gasto</MButton>
        </div>
      </div>
    </div>
  );
}

// ============================================================
// 22. Note modal (nueva nota)
// ============================================================
function ScreenNoteModal() {
  return (
    <div className="m-screen" style={{background:'rgba(0,0,0,0.42)'}}>
      <div style={{flex:1}}/>
      <div style={{background:'var(--color-bg)', borderTopLeftRadius:24, borderTopRightRadius:24, padding:'12px 0 28px', display:'flex', flexDirection:'column'}}>
        <div style={{width:38, height:5, borderRadius:5, background:'var(--color-line-2)', alignSelf:'center', marginBottom:14}}/>
        <div style={{padding:'0 20px 12px', display:'flex', alignItems:'flex-start'}}>
          <div style={{flex:1}}>
            <div style={{fontSize:11, fontFamily:'var(--font-mono)', color:'var(--color-ink-3)', textTransform:'uppercase', letterSpacing:0.7, fontWeight:600}}>PRJ-042 · Mampostería</div>
            <h2 style={{margin:'2px 0 0', fontSize:22, fontWeight:700, letterSpacing:-0.4}}>Nueva nota</h2>
          </div>
          <button style={{width:32, height:32, borderRadius:999, background:'var(--color-bg-sunken)', border:'none', display:'flex', alignItems:'center', justifyContent:'center'}}>
            <MIcon name="x" size={17} color="var(--color-ink-2)"/>
          </button>
        </div>

        <div style={{padding:'0 16px', display:'flex', flexDirection:'column'}}>
          <MFormGroup title="Nota">
            <MFormRow label="Título" value="Revisar dintel ventana W3" placeholder="Resumen corto" required/>
            <MFormRow label="Contenido" textarea value="El dintel de la ventana W3 quedó 3 cm más bajo. Hablar con M. Pérez para definir si se ajusta o se modifica plano." placeholder="Escribí los detalles…"/>
          </MFormGroup>

          <MFormGroup title="Etiquetas">
            <div style={{padding:'10px 14px', display:'flex', flexWrap:'wrap', gap:6}}>
              {[
                {l:'#urgente', tone:'bad'},
                {l:'#planos'},
                {l:'#revisión', active:true, tone:'warn'},
              ].map(t => (
                <button key={t.l} style={{
                  padding:'6px 12px', borderRadius:999,
                  background: t.active ? `color-mix(in oklab, var(--color-${t.tone||'accent'}) 14%, transparent)` : 'var(--color-bg-sunken)',
                  color: t.active ? `var(--color-${t.tone||'accent'})` : 'var(--color-ink-3)',
                  border: 'none',
                  fontSize:12.5, fontWeight:600, fontFamily:'var(--font-mono)',
                }}>{t.l}</button>
              ))}
              <button style={{padding:'6px 12px', borderRadius:999, background:'transparent', color:'var(--color-ink-4)', border:'1px dashed var(--color-line-2)', fontSize:12.5, fontWeight:600}}>+ etiqueta</button>
            </div>
          </MFormGroup>

          <MFormGroup title="Adjuntos y aviso">
            <MFormRow label="Adjuntar foto o documento" value="" placeholder="Tocá para elegir…" picker/>
            <MFormToggleRow label="Notificar a M. Pérez" sub="Recibirá una alerta cuando guardes." defaultChecked/>
          </MFormGroup>
        </div>

        <div style={{padding:'16px 20px 0', display:'flex', gap:10}}>
          <MButton variant="secondary" size="md" style={{flex:1}}>Cancelar</MButton>
          <MButton variant="primary" size="md" icon="check" style={{flex:1.4}}>Guardar nota</MButton>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, {
  ScreenMaterials, ScreenMaterialListDetail, ScreenNewMaterialListModal,
  ScreenBlueprints, ScreenTeam, ScreenDocs, ScreenNewProject,
  ScreenExpenseModal, ScreenNoteModal,
});
