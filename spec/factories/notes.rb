FactoryBot.define do
  factory :note do
    association :author, factory: [ :user, :constructor ]
    title { "Recordatorio" }
    body { "Coordinar con el plomero para mañana" }

    trait :on_project do
      association :noteable, factory: :project
    end

    trait :on_stage do
      association :noteable, factory: :project_stage
    end
  end
end
