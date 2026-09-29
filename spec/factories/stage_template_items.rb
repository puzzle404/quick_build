FactoryBot.define do
  factory :stage_template_item do
    association :stage_template
    sequence(:name) { |n| "Ítem #{n}" }
    position { 1 }
    start_offset_days { 0 }
    duration_days { 7 }
  end
end
