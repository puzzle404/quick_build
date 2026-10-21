# frozen_string_literal: true

require "rails_helper"

# Guardia de N+1 para la pantalla de la obra: los contadores de las tarjetas y
# de las pestañas se precomputan en el controller, así que agregar etapas NO
# tiene que agregar queries. Si este spec empieza a fallar, alguien volvió a
# contar de a una fila.
RSpec.describe "Constructors::Projects#show — presupuesto de queries", type: :request do
  let(:owner) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }

  before do
    allow(External::WeatherFetcher).to receive(:new).and_return(instance_double(External::WeatherFetcher, call: nil))
    sign_in(owner)
  end

  # `desde:` mantiene las posiciones únicas entre tandas. Con empates, dos
  # componentes que ordenan por position distinto arman listas de ids en
  # distinto orden y el SQL deja de ser idéntico (se pierde el query cache),
  # que es ruido y no un N+1.
  def build_stages!(roots:, subs_por_raiz:, desde: 0)
    Array.new(roots) do |i|
      root = create(:project_stage, project: project, position: desde + i, name: "Etapa #{desde + i}")
      Array.new(subs_por_raiz) do |j|
        sub = create(:project_stage, project: project, parent: root, position: j, name: "Sub #{desde + i}.#{j}")
        Document.insert_all([ { documentable_type: "ProjectStage", documentable_id: sub.id,
                                created_at: Time.current, updated_at: Time.current } ])
        sub
      end
      Image.insert_all([ { imageable_type: "ProjectStage", imageable_id: root.id,
                           created_at: Time.current, updated_at: Time.current } ])
      create(:material_list, project: project, project_stage: root)
      root
    end
  end

  it "no crece con la cantidad de etapas" do
    build_stages!(roots: 2, subs_por_raiz: 2)
    get constructors_project_path(project) # calienta caches de clases/vistas
    chicas = count_queries { get constructors_project_path(project) }
    expect(response).to have_http_status(:ok)

    build_stages!(roots: 6, subs_por_raiz: 3, desde: 2)
    grandes = count_queries { get constructors_project_path(project) }

    expect(response).to have_http_status(:ok)
    # 6 raíces y 18 sub-etapas más: contando de a una fila eran ~70 queries más.
    expect(grandes).to eq(chicas)
  end

  it "resuelve los conteos de las pestañas en una sola query" do
    build_stages!(roots: 2, subs_por_raiz: 1)
    get constructors_project_path(project)

    sql = capture_queries { get constructors_project_path(project) }
    tabs = sql.count { |q| q.include?("SELECT (SELECT COUNT(*)") }

    expect(tabs).to eq(1)
  end

  it "lee los adjuntos de todas las etapas con tres COUNT agrupados" do
    build_stages!(roots: 3, subs_por_raiz: 2)
    get constructors_project_path(project)

    sql = capture_queries { get constructors_project_path(project) }
    por_etapa = sql.select do |q|
      q.match?(/COUNT\(\*\)[^;]*"(documents|images|material_lists)"/) &&
        !q.include?("GROUP BY") &&          # los 3 agrupados de StageCounts
        !q.start_with?("SELECT (SELECT")    # el único de SectionCounts (tabs)
    end

    expect(por_etapa).to eq([])
  end
end
