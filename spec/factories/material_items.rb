FactoryBot.define do
  factory :material_item do
    association :material_list
    name { "Cemento Portland" }
    quantity { 10 }
    unit { "bolsa" }
    estimated_cost_cents { 15_000 }
  end
end
