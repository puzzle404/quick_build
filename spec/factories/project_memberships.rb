FactoryBot.define do
  factory :project_membership do
    association :user
    association :project
    role { 'worker' }
  end
end
