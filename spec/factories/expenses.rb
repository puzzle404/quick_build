FactoryBot.define do
  factory :expense do
    association :project
    association :author, factory: [ :user, :constructor ]
    amount_cents { 50_000_00 }
    currency { "ARS" }
    category { :labor }
    incurred_on { Date.current }
    description { "Pago de jornal" }

    trait :on_stage do
      after(:build) do |expense|
        expense.project_stage ||= build(:project_stage, project: expense.project)
      end
    end

    trait :with_receipt do
      after(:build) do |expense|
        expense.receipt.attach(
          io: StringIO.new("fake-image-bytes"),
          filename: "receipt.png",
          content_type: "image/png"
        )
      end
    end
  end
end
