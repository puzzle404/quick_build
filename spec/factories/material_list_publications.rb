FactoryBot.define do
  factory :material_list_publication do
    association :material_list
    visibility { :private }
  end
end
