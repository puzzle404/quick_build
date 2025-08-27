FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "Project #{n}" }
    association :owner, factory: [:user, :constructor]
  end
end
