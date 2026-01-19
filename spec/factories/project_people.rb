FactoryBot.define do
  factory :project_person do
    association :project
    full_name { "Juan Pérez" }
    role_title { "Oficial albañil" }
    status { :active }
    start_date { Date.current }
    notes { "Disponible por las mañanas." }
  end
end

