// Tweaks panel for Quick Build Mobile.
// Same pattern as the web version, adapted to mobile tokens (--color-*).

const M_THEMES = [
  { key: 'graphite', label: 'Graphite', attr: null,    swatch: '#1d232c' },
  { key: 'night',    label: 'Night',    attr: 'night', swatch: '#0f1b1f' },
];

const M_PALETTES = [
  { key: 'cobalt', label: 'Cobalto', accent: 'oklch(55% 0.22 255)' },
  { key: 'kiln',   label: 'Kiln',   accent: 'oklch(62% 0.19 45)'  },
  { key: 'moss',   label: 'Moss',   accent: 'oklch(55% 0.15 150)' },
  { key: 'safety', label: 'Safety', accent: 'oklch(75% 0.18 85)'  },
  { key: 'ink',    label: 'Ink',    accent: 'oklch(25% 0.02 255)' },
];

const M_DENSITIES = [
  { key: 'compact', label: 'Compacto' },
  { key: 'cozy',    label: 'Cómodo' },
  { key: 'relaxed', label: 'Espacioso' },
];

function applyMobileTweaks(t) {
  document.querySelectorAll('.m-screen').forEach(el => {
    // Theme
    if (t.theme === 'night') el.setAttribute('data-theme', 'night');
    else el.removeAttribute('data-theme');

    // Palette
    const p = M_PALETTES.find(p => p.key === t.palette);
    if (p) {
      el.style.setProperty('--color-accent', p.accent);
      el.style.setProperty('--color-accent-ink', 'oklch(99% 0.005 255)');
    } else {
      el.style.removeProperty('--color-accent');
      el.style.removeProperty('--color-accent-ink');
    }

    // Density — only font scale shift on mobile (touch targets stay 44pt min)
    const scale = t.density === 'compact' ? 0.94 : t.density === 'relaxed' ? 1.06 : 1;
    el.style.setProperty('font-size', `${15 * scale}px`);
  });
}

const M_DEFAULTS = {
  theme: 'graphite',
  palette: 'cobalt',
  density: 'cozy',
};

function MobileTweaksHost() {
  const [tweaks, setTweaks] = React.useState(M_DEFAULTS);
  const [open, setOpen] = React.useState(false);

  React.useEffect(() => { applyMobileTweaks(tweaks); }, [tweaks]);

  React.useEffect(() => {
    const handler = (e) => {
      const m = e.data || {};
      if (m.type === '__activate_edit_mode') setOpen(true);
      else if (m.type === '__deactivate_edit_mode') setOpen(false);
      else if (m.type === '__edit_mode_set_keys' && m.edits) {
        setTweaks(prev => ({ ...prev, ...m.edits }));
      }
    };
    window.addEventListener('message', handler);
    window.parent.postMessage({ type: '__edit_mode_available' }, '*');
    return () => window.removeEventListener('message', handler);
  }, []);

  if (!open) return null;

  const update = (patch) => {
    const next = { ...tweaks, ...patch };
    setTweaks(next);
    window.parent.postMessage({ type: '__edit_mode_set_keys', edits: patch }, '*');
  };

  return (
    <div style={{
      position: 'fixed', right: 16, bottom: 16, width: 300, zIndex: 200,
      background: '#ffffff', color: '#1a1f2e',
      border: '1px solid #d9d6cd', borderRadius: 12,
      boxShadow: '0 24px 60px rgba(0,0,0,0.22)', overflow: 'hidden',
      fontFamily: "'Geist', -apple-system, system-ui, sans-serif", fontSize: 12,
    }}>
      <div style={{
        display: 'flex', alignItems: 'center', padding: '10px 14px',
        borderBottom: '1px solid #e6e2d8', background: '#faf8f3',
      }}>
        <span style={{ fontSize: 14 }}>✨</span>
        <div style={{ marginLeft: 8, fontWeight: 700, fontSize: 13 }}>Tweaks · Mobile</div>
        <div style={{ flex: 1 }}/>
        <button onClick={() => setOpen(false)} style={{
          background: 'none', border: 'none', cursor: 'pointer',
          color: '#7d8290', fontSize: 16, lineHeight: 1, padding: 0,
        }}>×</button>
      </div>

      <div style={{ padding: 14, display: 'flex', flexDirection: 'column', gap: 14, maxHeight: '70vh', overflow: 'auto' }}>
        <MTweakSection label="Tema">
          <div style={{ display: 'flex', gap: 6 }}>
            {M_THEMES.map(t => (
              <button key={t.key} onClick={() => update({ theme: t.key })} style={mChip(tweaks.theme === t.key)}>
                <span style={{ width: 10, height: 10, borderRadius: 999, background: t.swatch, border: '1px solid #d9d6cd' }}/>
                {t.label}
              </button>
            ))}
          </div>
        </MTweakSection>

        <MTweakSection label="Paleta de acento">
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {M_PALETTES.map(p => (
              <button key={p.key} onClick={() => update({ palette: p.key })} style={mChip(tweaks.palette === p.key)}>
                <span style={{ width: 10, height: 10, borderRadius: 999, background: p.accent }}/>
                {p.label}
              </button>
            ))}
          </div>
        </MTweakSection>

        <MTweakSection label="Densidad">
          <div style={{ display: 'flex', gap: 6 }}>
            {M_DENSITIES.map(d => (
              <button key={d.key} onClick={() => update({ density: d.key })} style={mChip(tweaks.density === d.key)}>
                {d.label}
              </button>
            ))}
          </div>
        </MTweakSection>
      </div>
    </div>
  );
}

function MTweakSection({ label, children }) {
  return (
    <div>
      <div style={{
        fontSize: 10, fontFamily: "'Geist Mono', monospace",
        color: '#7d8290', textTransform: 'uppercase',
        letterSpacing: 0.8, marginBottom: 6, fontWeight: 600,
      }}>{label}</div>
      {children}
    </div>
  );
}

function mChip(active) {
  return {
    display: 'inline-flex', alignItems: 'center', gap: 6,
    padding: '4px 10px', height: 28,
    background: active ? '#f0ede3' : 'transparent',
    border: '1px solid ' + (active ? '#7d8290' : '#e6e2d8'),
    borderRadius: 6, color: '#1a1f2e', fontSize: 12,
    fontWeight: active ? 600 : 500, cursor: 'pointer',
  };
}

window.MobileTweaksHost = MobileTweaksHost;
