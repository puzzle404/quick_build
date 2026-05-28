// Canvas layout — renders all 22 iOS screens grouped by flow.

const Frame = ({ children }) => (
  <IOSDevice width={390} height={844}>{children}</IOSDevice>
);

function App() {
  return (
    <DesignCanvas>
      <DCSection id="auth" title="Autenticación · Onboarding" subtitle="Bienvenida, login y registro · Hotwire Native modal context">
        <DCArtboard id="welcome" label="01 · Welcome" width={420} height={870}><Frame><ScreenWelcome/></Frame></DCArtboard>
        <DCArtboard id="login"   label="02 · Login"   width={420} height={870}><Frame><ScreenLogin/></Frame></DCArtboard>
        <DCArtboard id="signup"  label="03 · Sign up" width={420} height={870}><Frame><ScreenSignup/></Frame></DCArtboard>
      </DCSection>

      <DCSection id="tabs" title="Tabs principales · raíz" subtitle="5 tabs nativos: Inicio · Proyectos · Buscar · Biblioteca · Perfil">
        <DCArtboard id="dashboard" label="04 · Dashboard / Inicio" width={420} height={870}><Frame><ScreenDashboard/></Frame></DCArtboard>
        <DCArtboard id="projects"  label="05 · Proyectos (lista)" width={420} height={870}><Frame><ScreenProjects/></Frame></DCArtboard>
        <DCArtboard id="search"    label="06 · Buscar"            width={420} height={870}><Frame><ScreenSearch/></Frame></DCArtboard>
        <DCArtboard id="library"   label="07 · Biblioteca"        width={420} height={870}><Frame><ScreenLibrary/></Frame></DCArtboard>
        <DCArtboard id="profile"   label="08 · Perfil / Ajustes"  width={420} height={870}><Frame><ScreenProfile/></Frame></DCArtboard>
      </DCSection>

      <DCSection id="project" title="Proyecto · Resumen y planificación" subtitle="Detalle de obra, etapas con sub-etapas, drawer">
        <DCArtboard id="overview"     label="09 · Project · Overview" width={420} height={870}><Frame><ScreenProjectOverview/></Frame></DCArtboard>
        <DCArtboard id="stages"       label="10 · Etapas (lista)"     width={420} height={870}><Frame><ScreenStages/></Frame></DCArtboard>
        <DCArtboard id="stage-detail" label="11 · Etapa · detalle"    width={420} height={870}><Frame><ScreenStageDetail/></Frame></DCArtboard>
        <DCArtboard id="new-stage"    label="12 · Nueva etapa · sheet"width={420} height={870}><Frame><ScreenNewStageModal/></Frame></DCArtboard>
        <DCArtboard id="template"     label="13 · Plantilla · sheet"  width={420} height={870}><Frame><ScreenTemplateModal/></Frame></DCArtboard>
      </DCSection>

      <DCSection id="materials" title="Materiales" subtitle="Listas → ítems · soporte manual / PDF / Excel">
        <DCArtboard id="mat-list"   label="14 · Listas de materiales" width={420} height={870}><Frame><ScreenMaterials/></Frame></DCArtboard>
        <DCArtboard id="mat-detail" label="15 · Detalle de lista"      width={420} height={870}><Frame><ScreenMaterialListDetail/></Frame></DCArtboard>
        <DCArtboard id="mat-new"    label="16 · Nueva lista · sheet"   width={420} height={870}><Frame><ScreenNewMaterialListModal/></Frame></DCArtboard>
      </DCSection>

      <DCSection id="content" title="Contenido del proyecto" subtitle="Planos · IA, equipo y documentos">
        <DCArtboard id="blueprints" label="17 · Planos · IA"  width={420} height={870}><Frame><ScreenBlueprints/></Frame></DCArtboard>
        <DCArtboard id="team"       label="18 · Equipo"        width={420} height={870}><Frame><ScreenTeam/></Frame></DCArtboard>
        <DCArtboard id="docs"       label="19 · Documentos"    width={420} height={870}><Frame><ScreenDocs/></Frame></DCArtboard>
      </DCSection>

      <DCSection id="creation" title="Creación y entrada rápida" subtitle="Modales y wizards desde acciones rápidas">
        <DCArtboard id="new-project" label="20 · Nuevo proyecto · paso 1" width={420} height={870}><Frame><ScreenNewProject/></Frame></DCArtboard>
        <DCArtboard id="expense"     label="21 · Gasto · sheet"          width={420} height={870}><Frame><ScreenExpenseModal/></Frame></DCArtboard>
        <DCArtboard id="note"        label="22 · Nota · sheet"           width={420} height={870}><Frame><ScreenNoteModal/></Frame></DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.Fragment>
    <App/>
    <MobileTweaksHost/>
  </React.Fragment>
);
