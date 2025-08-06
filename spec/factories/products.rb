FactoryBot.define do
  factory :product do
    name { "MyString" }
    price_cents { 1 }
    description { "MyText" }
    association :company
    association :category
  end
end
