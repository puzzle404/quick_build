FactoryBot.define do
  factory :person_attendance do
    association :project_person
    occurred_at { Time.current }
    latitude { -34.6037 }
    longitude { -58.3816 }
    source { "manual" }
  end
end

