FactoryBot.define do
  factory :stage_template do
    sequence(:name) { |n| "Plantilla #{n}" }
    description { "Estructura de obra reutilizable" }
    association :owner, factory: [ :user, :constructor ]

    trait :builtin do
      owner { nil }
      builtin { true }
    end
  end
end
