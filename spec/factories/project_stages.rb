FactoryBot.define do
  factory :project_stage do
    association :project
    name { "Etapa inicial" }
    description { "Trabajos preliminares" }
    start_date { Date.current }
    end_date { Date.current + 7.days }
  end
end
