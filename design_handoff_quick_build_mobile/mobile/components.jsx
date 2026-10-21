// Mobile-first primitives for the iOS Quick Build app.
// Lives on top of the same Qb design tokens (mobile/tokens.css).

// -------- Icons (mobile-flavored, 22px default) --------
function MIcon({ name, size = 22, color = 'currentColor', stroke = 1.8 }) {
  const c = { width: size, height: size, viewBox: '0 0 24 24', fill: 'none', stroke: color, strokeWidth: stroke, strokeLinecap: 'round', strokeLinejoin: 'round' };
  switch (name) {
    case 'home':       return <svg {...c}><path d="M3 11.5L12 4l9 7.5"/><path d="M5 10.5V20h14v-9.5"/></svg>;
    case 'projects':   return <svg {...c}><path d="M3 7h6l2 2h10v11H3z"/></svg>;
    case 'search':     return <svg {...c}><circle cx="11" cy="11" r="7"/><path d="M20 20l-4-4"/></svg>;
    case 'library':    return <svg {...c}><path d="M4 4h6v16H4zM14 4h6v16h-6z"/><path d="M4 9h6M14 9h6"/></svg>;
    case 'user':       return <svg {...c}><circle cx="12" cy="8" r="3.5"/><path d="M4 20c0-4 3.5-6 8-6s8 2 8 6"/></svg>;
    case 'plus':       return <svg {...c}><path d="M12 5v14M5 12h14"/></svg>;
    case 'check':      return <svg {...c}><path d="M5 13l4 4 10-10"/></svg>;
    case 'chev-right': return <svg {...c}><path d="M9 5l7 7-7 7"/></svg>;
    case 'chev-down':  return <svg {...c}><path d="M5 9l7 7 7-7"/></svg>;
    case 'chev-left':  return <svg {...c}><path d="M15 19l-7-7 7-7"/></svg>;
    case 'arrow-right':return <svg {...c}><path d="M5 12h14M13 5l7 7-7 7"/></svg>;
    case 'arrow-up':   return <svg {...c}><path d="M12 19V5M6 11l6-6 6 6"/></svg>;
    case 'arrow-down': return <svg {...c}><path d="M12 5v14M6 13l6 6 6-6"/></svg>;
    case 'filter':     return <svg {...c}><path d="M4 6h16l-6 8v5l-4-1v-4z"/></svg>;
    case 'bell':       return <svg {...c}><path d="M6 8a6 6 0 1112 0c0 7 3 8 3 8H3s3-1 3-8"/><path d="M10 20a2 2 0 004 0"/></svg>;
    case 'cog':        return <svg {...c}><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 00.3 1.8l.1.1a2 2 0 11-2.8 2.8l-.1-.1a1.7 1.7 0 00-1.8-.3 1.7 1.7 0 00-1 1.5V21a2 2 0 11-4 0v-.1a1.7 1.7 0 00-1-1.5 1.7 1.7 0 00-1.8.3l-.1.1a2 2 0 11-2.8-2.8l.1-.1a1.7 1.7 0 00.3-1.8 1.7 1.7 0 00-1.5-1H3a2 2 0 110-4h.1a1.7 1.7 0 001.5-1 1.7 1.7 0 00-.3-1.8l-.1-.1a2 2 0 112.8-2.8l.1.1a1.7 1.7 0 001.8.3h0a1.7 1.7 0 001-1.5V3a2 2 0 114 0v.1a1.7 1.7 0 001 1.5 1.7 1.7 0 001.8-.3l.1-.1a2 2 0 112.8 2.8l-.1.1a1.7 1.7 0 00-.3 1.8v0a1.7 1.7 0 001.5 1H21a2 2 0 110 4h-.1a1.7 1.7 0 00-1.5 1z"/></svg>;
    case 'calendar':   return <svg {...c}><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9h18M8 3v4M16 3v4"/></svg>;
    case 'map-pin':    return <svg {...c}><path d="M12 22s7-7.5 7-13a7 7 0 10-14 0c0 5.5 7 13 7 13z"/><circle cx="12" cy="9" r="2.5"/></svg>;
    case 'doc':        return <svg {...c}><path d="M6 3h9l4 4v14H6z"/><path d="M14 3v5h5"/></svg>;
    case 'image':      return <svg {...c}><rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><path d="M4 19l5-5 4 4 3-3 4 4"/></svg>;
    case 'materials':  return <svg {...c}><path d="M12 3l9 5-9 5-9-5z"/><path d="M3 13l9 5 9-5"/></svg>;
    case 'stages':     return <svg {...c}><path d="M3 6h18M3 12h18M3 18h12"/></svg>;
    case 'blueprint':  return <svg {...c}><path d="M4 5h16v14H4z"/><path d="M8 5v14M4 10h4M4 15h4M20 10h-4M16 5v14"/></svg>;
    case 'people':     return <svg {...c}><circle cx="9" cy="8" r="3"/><path d="M3 20c0-3.5 2.7-6 6-6s6 2.5 6 6"/><circle cx="17" cy="9" r="2.5"/><path d="M15 20c0-2.5 1.5-4.5 4-4.5"/></svg>;
    case 'money':      return <svg {...c}><rect x="3" y="6" width="18" height="12" rx="2"/><circle cx="12" cy="12" r="2.5"/></svg>;
    case 'note':       return <svg {...c}><path d="M5 4h11l4 4v12H5z"/><path d="M9 12h7M9 16h5"/></svg>;
    case 'sparkles':   return <svg {...c}><path d="M12 3l1.6 4 4 1.6-4 1.6L12 14l-1.6-3.8L6.4 8.6 10.4 7z"/><path d="M19 14l1 2 2 1-2 1-1 2-1-2-2-1 2-1z"/></svg>;
    case 'upload':     return <svg {...c}><path d="M12 4v12M6 10l6-6 6 6M4 20h16"/></svg>;
    case 'download':   return <svg {...c}><path d="M12 4v12M6 14l6 6 6-6M4 20h16"/></svg>;
    case 'more':       return <svg {...c}><circle cx="6" cy="12" r="1.4" fill={color} stroke="none"/><circle cx="12" cy="12" r="1.4" fill={color} stroke="none"/><circle cx="18" cy="12" r="1.4" fill={color} stroke="none"/></svg>;
    case 'x':          return <svg {...c}><path d="M6 6l12 12M6 18L18 6"/></svg>;
    case 'edit':       return <svg {...c}><path d="M14 4l6 6-11 11H3v-6z"/><path d="M13 5l6 6"/></svg>;
    case 'qr':         return <svg {...c}><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><path d="M14 14h3v3M14 19h3M19 14v3M19 19v2h2"/></svg>;
    case 'shield':     return <svg {...c}><path d="M12 3l8 3v6c0 5-4 8-8 9-4-1-8-4-8-9V6z"/></svg>;
    case 'clock':      return <svg {...c}><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>;
    case 'pin':        return <svg {...c}><path d="M12 3l4 4-2 2 3 3-5 1-1 5-3-3-4 2 2-4-3-3 5-1 2-2z"/></svg>;
    default:           return <svg {...c}><circle cx="12" cy="12" r="4"/></svg>;
  }
}

// -------- Tiny status dot --------
function MDot({ tone = 'ok' }) {
  const color = { ok:'var(--color-ok)', warn:'var(--color-warn)', bad:'var(--color-bad)', info:'var(--color-info)', muted:'var(--color-ink-4)', accent:'var(--color-accent)' }[tone];
  return <span style={{display:'inline-block', width:8, height:8, borderRadius:999, background:color, boxShadow:`0 0 0 3px ${color}22`}}/>;
}

// -------- Pill --------
function MPill({ tone = 'muted', children, mono, dense }) {
  const p = {
    ok:    { bg:'color-mix(in oklab, var(--color-ok) 14%, transparent)',   fg:'var(--color-ok)' },
    warn:  { bg:'color-mix(in oklab, var(--color-warn) 18%, transparent)', fg:'var(--color-warn)' },
    bad:   { bg:'color-mix(in oklab, var(--color-bad) 16%, transparent)',  fg:'var(--color-bad)' },
    info:  { bg:'color-mix(in oklab, var(--color-info) 14%, transparent)', fg:'var(--color-info)' },
    accent:{ bg:'color-mix(in oklab, var(--color-accent) 14%, transparent)', fg:'var(--color-accent)' },
    muted: { bg:'var(--color-bg-sunken)', fg:'var(--color-ink-3)' },
  }[tone];
  return <span style={{
    display:'inline-flex', alignItems:'center', gap:4,
    padding: dense ? '2px 8px' : '3px 10px',
    fontSize: 12, fontWeight: 600, letterSpacing: 0.2,
    borderRadius: 999, background: p.bg, color: p.fg,
    fontFamily: mono ? 'var(--font-mono)' : 'inherit',
    whiteSpace:'nowrap', lineHeight: 1.3,
  }}>{children}</span>;
}

// -------- Progress bar --------
function MBar({ value = 0, plan = null, tone = 'accent', height = 6, showPlan = false }) {
  const color = { accent:'var(--color-accent)', ok:'var(--color-ok)', warn:'var(--color-warn)', bad:'var(--color-bad)', info:'var(--color-info)', ink:'var(--color-ink-2)', muted:'var(--color-ink-4)' }[tone];
  return (
    <div style={{position:'relative', width:'100%', height, background:'var(--color-line)', borderRadius:999, overflow:'hidden'}}>
      <div style={{position:'absolute', inset:0, width:`${Math.min(100, value)}%`, background:color, borderRadius:999}}/>
      {showPlan && plan != null && (
        <div style={{position:'absolute', top:-2, bottom:-2, left:`${Math.min(100, plan)}%`, width:1, background:'var(--color-ink-2)'}}/>
      )}
    </div>
  );
}

// -------- Avatar --------
function MAvatar({ name = '??', size = 32, tone }) {
  const initials = name.split(' ').filter(Boolean).map(s => s[0]).slice(0,2).join('').toUpperCase();
  const hash = name.split('').reduce((a, c) => a + c.charCodeAt(0), 0);
  const hue = hash % 360;
  return (
    <div style={{
      width:size, height:size, borderRadius:999,
      display:'inline-flex', alignItems:'center', justifyContent:'center',
      background: tone || `oklch(82% 0.045 ${hue})`,
      color: `oklch(28% 0.06 ${hue})`,
      fontSize: size*0.4, fontWeight: 600, letterSpacing:0.2, flexShrink:0,
      fontFamily:'var(--font-ui)',
    }}>{initials}</div>
  );
}

// -------- Section header (Apple grouped style) --------
function MSection({ title, action, children, padded = true }) {
  return (
    <div style={{marginBottom: 18}}>
      {(title || action) && (
        <div style={{display:'flex', alignItems:'center', justifyContent:'space-between', padding:'0 20px 8px'}}>
          <span style={{fontSize: 12, fontFamily:'var(--font-mono)', color:'var(--color-ink-3)', textTransform:'uppercase', letterSpacing: 0.8, fontWeight: 600}}>{title}</span>
          {action}
        </div>
      )}
      <div style={padded ? {padding:'0 16px'} : {}}>{children}</div>
    </div>
  );
}

// -------- Card --------
function MCard({ children, padding = 14, onClick, style = {} }) {
  return (
    <div onClick={onClick} style={{
      background:'var(--color-bg-raised)',
      border:'1px solid var(--color-line)',
      borderRadius: 14,
      padding,
      cursor: onClick ? 'pointer' : 'default',
      ...style,
    }}>{children}</div>
  );
}

// -------- iOS-style row inside a grouped card --------
function MRow({ icon, iconBg, title, subtitle, value, hint, chevron = true, isLast = false, onClick }) {
  return (
    <div onClick={onClick} style={{
      display:'flex', alignItems:'center', minHeight:56, padding:'10px 14px',
      borderBottom: isLast ? 'none' : '1px solid var(--color-line)',
      cursor: onClick ? 'pointer' : 'default',
    }}>
      {icon && (
        <div style={{
          width:32, height:32, borderRadius:8, background: iconBg || 'var(--color-bg-sunken)',
          color:'var(--color-ink-2)', display:'flex', alignItems:'center', justifyContent:'center', marginRight:12, flexShrink:0,
        }}>{typeof icon === 'string' ? <MIcon name={icon} size={17}/> : icon}</div>
      )}
      <div style={{flex:1, minWidth:0}}>
        <div style={{fontSize:15, fontWeight:500, color:'var(--color-ink)'}}>{title}</div>
        {subtitle && <div style={{fontSize:12.5, color:'var(--color-ink-3)', marginTop:2}}>{subtitle}</div>}
      </div>
      {value && <span style={{fontSize:14, color:'var(--color-ink-3)', marginRight:8, fontFamily: hint ? 'var(--font-mono)' : 'inherit', fontVariantNumeric:'tabular-nums'}}>{value}</span>}
      {chevron && <MIcon name="chev-right" size={16} color="var(--color-ink-4)" stroke={2.2}/>}
    </div>
  );
}

// -------- Page header (large title, iOS style) --------
function MPageHeader({ eyebrow, title, subtitle, action, dense = false }) {
  return (
    <div style={{padding: dense ? '8px 20px 12px' : '8px 20px 20px'}}>
      {eyebrow && <div style={{fontSize:12, fontFamily:'var(--font-mono)', color:'var(--color-ink-3)', textTransform:'uppercase', letterSpacing:0.8, marginBottom:6, fontWeight:600}}>{eyebrow}</div>}
      <div style={{display:'flex', alignItems:'flex-start', gap:12}}>
        <h1 style={{margin:0, flex:1, fontSize: dense ? 24 : 32, fontWeight:700, letterSpacing: -0.6, color:'var(--color-ink)', lineHeight: 1.1}}>{title}</h1>
        {action}
      </div>
      {subtitle && <div style={{fontSize:14, color:'var(--color-ink-3)', marginTop:6, lineHeight: 1.4}}>{subtitle}</div>}
    </div>
  );
}

// -------- iOS-style nav (back + title-or-pill + right) --------
function MNavBar({ back = true, title, right }) {
  return (
    <div style={{display:'flex', alignItems:'center', padding:'8px 12px 6px', gap:8, minHeight:48}}>
      {back ? (
        <button style={{
          width:36, height:36, display:'inline-flex', alignItems:'center', justifyContent:'center',
          background:'transparent', border:'none', color:'var(--color-accent)', padding:0,
        }}>
          <MIcon name="chev-left" size={24} stroke={2.4}/>
        </button>
      ) : <div style={{width:36}}/>}
      <div style={{flex:1, textAlign:'center', fontSize:16, fontWeight:600, color:'var(--color-ink)'}}>{title}</div>
      <div style={{minWidth:36, display:'flex', justifyContent:'flex-end'}}>{right}</div>
    </div>
  );
}

// -------- Bottom tab bar (4 tabs) --------
function MTabBar({ active = 'home' }) {
  const tabs = [
    { k:'home',     l:'Inicio',    i:'home' },
    { k:'projects', l:'Proyectos', i:'projects' },
    { k:'search',   l:'Buscar',    i:'search' },
    { k:'library',  l:'Biblio.',   i:'library' },
    { k:'me',       l:'Perfil',    i:'user' },
  ];
  return (
    <div style={{
      position:'sticky', bottom: 0, left: 0, right: 0,
      paddingBottom: 24, // safe area
      background:'color-mix(in oklab, var(--color-bg) 88%, transparent)',
      backdropFilter:'blur(20px) saturate(180%)',
      WebkitBackdropFilter:'blur(20px) saturate(180%)',
      borderTop:'0.5px solid var(--color-line)',
      display:'flex', justifyContent:'space-around', alignItems:'flex-start',
      paddingTop: 8,
    }}>
      {tabs.map(t => {
        const isActive = active === t.k;
        return (
          <button key={t.k} style={{
            background:'transparent', border:'none', padding:'4px 6px',
            display:'flex', flexDirection:'column', alignItems:'center', gap:2,
            color: isActive ? 'var(--color-accent)' : 'var(--color-ink-3)',
            minWidth: 56,
          }}>
            <MIcon name={t.i} size={22} stroke={isActive ? 2.2 : 1.8}/>
            <span style={{fontSize: 10, fontWeight: isActive ? 600 : 500, letterSpacing: 0.1}}>{t.l}</span>
          </button>
        );
      })}
    </div>
  );
}

// -------- Button --------
function MButton({ children, variant = 'primary', size = 'md', icon, iconRight, onClick, full = false, style = {} }) {
  const variants = {
    primary:   { bg:'var(--color-accent)', fg:'var(--color-accent-ink)', bd:'transparent' },
    secondary: { bg:'var(--color-bg-raised)', fg:'var(--color-ink)', bd:'var(--color-line-2)' },
    ghost:     { bg:'transparent', fg:'var(--color-accent)', bd:'transparent' },
    danger:    { bg:'transparent', fg:'var(--color-bad)', bd:'color-mix(in oklab, var(--color-bad) 30%, var(--color-line))' },
    fill:      { bg:'var(--color-accent-soft)', fg:'var(--color-accent)', bd:'transparent' },
  };
  const v = variants[variant];
  const sizes = {
    sm: { h: 36, padding:'0 14px', fontSize: 13 },
    md: { h: 44, padding:'0 18px', fontSize: 15 },
    lg: { h: 52, padding:'0 22px', fontSize: 16 },
  };
  const s = sizes[size];
  return (
    <button onClick={onClick} style={{
      width: full ? '100%' : 'auto',
      height: s.h, padding: s.padding, fontSize: s.fontSize,
      background: v.bg, color: v.fg, border: `1px solid ${v.bd}`,
      borderRadius: 999, fontWeight: 600, letterSpacing: -0.2,
      display:'inline-flex', alignItems:'center', justifyContent:'center', gap: 8,
      ...style,
    }}>
      {icon && <MIcon name={icon} size={17} stroke={2.2}/>}
      {children}
      {iconRight && <MIcon name={iconRight} size={17} stroke={2.2}/>}
    </button>
  );
}

// -------- KPI card (rounded, soft accent) --------
function MKpi({ label, value, delta, deltaTone = 'muted', icon, gradient, hint }) {
  const grads = {
    violet:  'linear-gradient(135deg, oklch(42% 0.22 295) 0%, oklch(55% 0.24 285) 100%)',
    amber:   'linear-gradient(135deg, oklch(62% 0.22 45)  0%, oklch(72% 0.21 55)  100%)',
    sky:     'linear-gradient(135deg, oklch(50% 0.20 250) 0%, oklch(62% 0.22 230) 100%)',
    emerald: 'linear-gradient(135deg, oklch(45% 0.15 165) 0%, oklch(58% 0.15 155) 100%)',
  };
  const onColor = gradient ? 'white' : 'var(--color-ink)';
  const onColor2 = gradient ? 'rgba(255,255,255,0.78)' : 'var(--color-ink-3)';
  return (
    <div style={{
      background: gradient ? grads[gradient] : 'var(--color-bg-raised)',
      border: gradient ? 'none' : '1px solid var(--color-line)',
      borderRadius: 16, padding: 14,
      color: onColor,
      position:'relative', overflow:'hidden',
      minHeight: 96, display:'flex', flexDirection:'column', justifyContent:'space-between',
    }}>
      {gradient && <div style={{position:'absolute', top:-30, right:-30, width:120, height:120, borderRadius:999, border:'1.5px solid rgba(255,255,255,0.16)'}}/>}
      <div style={{display:'flex', alignItems:'center', gap:8, position:'relative'}}>
        {icon && (
          <div style={{
            width:28, height:28, borderRadius:8,
            background: gradient ? 'rgba(255,255,255,0.18)' : 'var(--color-bg-sunken)',
            color: onColor, display:'flex', alignItems:'center', justifyContent:'center',
          }}><MIcon name={icon} size={15}/></div>
        )}
        <span style={{fontSize: 11, fontFamily:'var(--font-mono)', letterSpacing: 0.7, textTransform:'uppercase', fontWeight: 600, color: onColor2}}>{label}</span>
      </div>
      <div style={{position:'relative'}}>
        <div className="mono tnum" style={{fontSize: 30, fontWeight: 600, letterSpacing: -1, lineHeight: 1, color: onColor}}>{value}</div>
        {hint && <div style={{fontSize: 11, color: onColor2, marginTop: 4}}>{hint}</div>}
        {delta && (
          <div style={{fontSize: 11.5, marginTop: 4, color: deltaTone === 'ok' ? (gradient ? 'rgba(255,255,255,0.85)' : 'var(--color-ok)') : deltaTone === 'warn' ? 'var(--color-warn)' : onColor2, fontWeight: 600}}>
            {delta}
          </div>
        )}
      </div>
    </div>
  );
}

// -------- Sticky tabs (segmented control style) --------
function MSegmented({ options, value, onChange }) {
  return (
    <div style={{
      background:'var(--color-bg-sunken)', borderRadius: 10, padding: 3,
      display:'inline-flex', position:'relative',
    }}>
      {options.map(o => {
        const active = value === o.k;
        return (
          <button key={o.k} onClick={() => onChange && onChange(o.k)} style={{
            padding:'7px 14px', fontSize: 13, fontWeight: active ? 600 : 500,
            background: active ? 'var(--color-bg-raised)' : 'transparent',
            color: active ? 'var(--color-ink)' : 'var(--color-ink-3)',
            border:'none', borderRadius: 8,
            boxShadow: active ? '0 1px 2px rgba(0,0,0,0.08)' : 'none',
            transition:'all .15s',
          }}>{o.l}</button>
        );
      })}
    </div>
  );
}

// -------- Helpers --------
function fmtARS(n) {
  if (n == null) return '—';
  if (Math.abs(n) >= 1_000_000) return `$ ${(n/1_000_000).toFixed(1)}M`;
  if (Math.abs(n) >= 1_000)     return `$ ${(n/1_000).toFixed(0)}k`;
  return `$ ${n}`;
}
function fmtARSFull(n) { return n == null ? '—' : '$ ' + Math.round(n).toLocaleString('es-AR'); }
function fmtDate(iso) {
  if (!iso || iso === '—') return '—';
  const d = new Date(iso);
  return d.toLocaleDateString('es-AR', { day: '2-digit', month: 'short' });
}

// -------- Underline tabs (filter / scope tabs — new design system) --------
// Replaces the old chip pattern. Usage:
//   <MTabs value={k} onChange={setK} options={[{k:'all', l:'Todos', c:9}, ...]}/>
function MTabs({ options, value, onChange }) {
  return (
    <div style={{
      padding: '0 16px',
      borderBottom: '1px solid var(--color-line)',
      overflowX: 'auto', display: 'flex', gap: 18,
      scrollbarWidth: 'none',
    }}>
      {options.map(o => {
        const active = (value === o.k) || (!value && o.active);
        return (
          <button key={o.k || o.l} onClick={() => onChange && onChange(o.k)} style={{
            padding: '10px 0', border: 'none', background: 'transparent',
            borderBottom: `2px solid ${active ? 'var(--color-accent)' : 'transparent'}`,
            color: active ? 'var(--color-ink)' : 'var(--color-ink-3)',
            fontWeight: active ? 700 : 500, fontSize: 13.5,
            marginBottom: -1, display: 'inline-flex', alignItems: 'center', gap: 6,
            whiteSpace: 'nowrap', letterSpacing: -0.1,
          }}>
            {o.icon && <MIcon name={o.icon} size={14} stroke={active ? 2 : 1.8}/>}
            {o.l}
            {o.c != null && (
              <span style={{
                fontFamily: 'var(--font-mono)', fontSize: 10.5, fontWeight: 700,
                padding: '1px 6px', borderRadius: 4,
                background: active ? 'color-mix(in oklab, var(--color-accent) 14%, transparent)' : 'var(--color-bg-sunken)',
                color: active ? 'var(--color-accent)' : 'var(--color-ink-4)',
              }}>{o.c}</span>
            )}
          </button>
        );
      })}
    </div>
  );
}

// -------- iOS-style grouped form (inset rows, big touch targets) --------
// Usage:
//   <MFormGroup title="Datos básicos">
//     <MFormRow label="Nombre" value="..." />
//     <MFormRow label="Descripción" textarea value="..." />
//   </MFormGroup>
function MFormGroup({ title, footnote, children }) {
  // Flatten + clone children, mark the last one with isLast for divider styling
  const items = React.Children.toArray(children).filter(Boolean);
  return (
    <div style={{ marginBottom: 18 }}>
      {title && (
        <div style={{
          padding: '0 4px 8px', fontSize: 11.5, fontWeight: 600,
          color: 'var(--color-ink-3)', textTransform: 'uppercase',
          letterSpacing: 0.6, fontFamily: 'var(--font-mono)',
        }}>{title}</div>
      )}
      <div style={{
        background: 'var(--color-bg-raised)',
        border: '1px solid var(--color-line)',
        borderRadius: 14, overflow: 'hidden',
      }}>
        {items.map((c, i) => {
          const isLast = i === items.length - 1;
          // Only inject `isLast` on our form components (function types).
          // Raw DOM nodes (like a wrapping <div> for radio cards) don't need it.
          return typeof c.type === 'function'
            ? React.cloneElement(c, { isLast, key: c.key ?? i })
            : React.cloneElement(c, { key: c.key ?? i, style: { ...(c.props.style || {}), borderBottom: isLast ? 'none' : '1px solid var(--color-line)' } });
        })}
      </div>
      {footnote && (
        <div style={{ padding: '8px 4px 0', fontSize: 11.5, color: 'var(--color-ink-3)', lineHeight: 1.4 }}>{footnote}</div>
      )}
    </div>
  );
}

function MFormRow({ label, value, defaultValue, placeholder, type = 'text', textarea = false, select = false, options, trailing, helper, required, isLast, picker, onChange }) {
  // Two layouts:
  //  - picker=true → iOS settings-style row: label LEFT, value RIGHT with chevron. Looks tappable.
  //  - default     → label small caps on top, then a clearly-visible input chip with bg-sunken + ring on focus.

  if (picker) {
    return (
      <button onClick={onChange} style={{
        display:'flex', alignItems:'center', gap:10, width:'100%',
        padding:'14px 16px', background:'transparent', border:'none', cursor:'pointer', textAlign:'left',
        borderBottom: isLast ? 'none' : '1px solid var(--color-line)',
      }}>
        <span style={{flex:'0 0 auto', fontSize:15, fontWeight:500, color:'var(--color-ink)'}}>{label}{required && <span style={{color:'var(--color-bad)', marginLeft:2}}>*</span>}</span>
        <span style={{flex:1, textAlign:'right', fontSize:15, color: value ? 'var(--color-ink-2)' : 'var(--color-ink-4)', whiteSpace:'nowrap', overflow:'hidden', textOverflow:'ellipsis'}}>{value || placeholder || 'Elegir…'}</span>
        {trailing || <MIcon name="chev-right" size={15} color="var(--color-ink-4)" stroke={2.2}/>}
      </button>
    );
  }

  const inputBase = {
    width:'100%', padding:'10px 12px', minHeight:42,
    background:'var(--color-bg-sunken)',
    border:'1px solid var(--color-line)', borderRadius: 10,
    fontSize: 15.5, color:'var(--color-ink)',
    fontFamily:'inherit', fontWeight: 500,
    outline:'none', boxSizing:'border-box',
    transition:'border-color .15s, background .15s',
  };

  return (
    <div style={{
      padding:'12px 14px',
      borderBottom: isLast ? 'none' : '1px solid var(--color-line)',
    }}>
      <label style={{
        display:'flex', alignItems:'center', gap:4,
        fontSize:11, fontWeight:600, color:'var(--color-ink-3)',
        marginBottom: 6, letterSpacing: 0.4, textTransform:'uppercase',
        fontFamily:'var(--font-mono)',
      }}>
        {label}
        {required && <span style={{color:'var(--color-bad)'}}>*</span>}
      </label>
      <div style={{position:'relative'}}>
        {textarea ? (
          <textarea defaultValue={defaultValue ?? value} placeholder={placeholder} rows={3} style={{...inputBase, resize:'vertical', lineHeight:1.5, minHeight:80}}/>
        ) : select ? (
          <div style={{position:'relative'}}>
            <select defaultValue={defaultValue ?? value} style={{...inputBase, appearance:'none', WebkitAppearance:'none', paddingRight:36}}>
              {options && options.map(o => <option key={o}>{o}</option>)}
            </select>
            <div style={{position:'absolute', right:12, top:'50%', transform:'translateY(-50%)', pointerEvents:'none'}}>
              <MIcon name="chev-down" size={14} color="var(--color-ink-3)"/>
            </div>
          </div>
        ) : (
          <div style={{position:'relative'}}>
            <input type={type} defaultValue={defaultValue ?? value} placeholder={placeholder} style={{...inputBase, paddingRight: trailing ? 38 : 12}}/>
            {trailing && (
              <div style={{position:'absolute', right:10, top:'50%', transform:'translateY(-50%)', pointerEvents:'none'}}>{trailing}</div>
            )}
          </div>
        )}
      </div>
      {helper && (
        <div style={{fontSize:11.5, color:'var(--color-ink-3)', marginTop:5, lineHeight:1.4}}>{helper}</div>
      )}
    </div>
  );
}

// -------- Toggle-style form row (label + switch-looking control) --------
function MFormToggleRow({ label, sub, defaultChecked, isLast }) {
  return (
    <label style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '12px 14px',
      borderBottom: isLast ? 'none' : '1px solid var(--color-line)',
      cursor: 'pointer',
    }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14.5, fontWeight: 500, color: 'var(--color-ink)' }}>{label}</div>
        {sub && <div style={{ fontSize: 12, color: 'var(--color-ink-3)', marginTop: 2 }}>{sub}</div>}
      </div>
      <input type="checkbox" defaultChecked={defaultChecked} style={{
        appearance: 'none', WebkitAppearance: 'none',
        width: 44, height: 26, borderRadius: 999,
        background: defaultChecked ? 'var(--color-ok)' : 'var(--color-line-2)',
        position: 'relative', cursor: 'pointer', transition: 'background .2s',
        flexShrink: 0,
      }}/>
    </label>
  );
}

// -------- Currency / number row (clearly-visible amount input) --------
function MFormAmountRow({ label, value, currency = '$', isLast, sub }) {
  return (
    <div style={{
      padding:'12px 14px',
      borderBottom: isLast ? 'none' : '1px solid var(--color-line)',
    }}>
      <label style={{
        display:'block', fontSize:11, fontWeight:600, color:'var(--color-ink-3)',
        marginBottom: 6, letterSpacing: 0.4, textTransform:'uppercase', fontFamily:'var(--font-mono)',
      }}>{label}</label>
      <div style={{
        display:'flex', alignItems:'baseline', gap:4, padding:'8px 12px',
        background:'var(--color-bg-sunken)', border:'1px solid var(--color-line)', borderRadius:10,
      }}>
        <span style={{fontSize:17, color:'var(--color-ink-3)', fontWeight:500}}>{currency}</span>
        <input defaultValue={value} style={{
          flex:1, border:'none', outline:'none', background:'transparent',
          fontSize:22, fontFamily:'var(--font-mono)', fontVariantNumeric:'tabular-nums',
          fontWeight:700, letterSpacing:-0.5, color:'var(--color-ink)', padding:0,
        }}/>
      </div>
      {sub && <div style={{fontSize:11.5, color:'var(--color-ink-3)', marginTop:5}}>{sub}</div>}
    </div>
  );
}

Object.assign(window, {
  MIcon, MDot, MPill, MBar, MAvatar, MSection, MCard, MRow,
  MPageHeader, MNavBar, MTabBar, MButton, MKpi, MSegmented,
  MTabs, MFormGroup, MFormRow, MFormToggleRow, MFormAmountRow,
  fmtARS, fmtARSFull, fmtDate,
});


