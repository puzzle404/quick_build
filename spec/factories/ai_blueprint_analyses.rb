FactoryBot.define do
  factory :ai_blueprint_analysis do
    blueprint { nil }
    status { "MyString" }
    raw_response { "" }
    suggested_measurements { "" }
    applied_at { "2025-12-05 18:43:43" }
    error_message { "MyText" }
  end
end
