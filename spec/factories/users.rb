FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password" }
    role { :buyer }

    trait :seller do
      role { :seller }
      association :company
    end

    trait :constructor do
      role { :constructor }
    end

    trait :admin do
      role { :admin }
    end
  end
end
