FactoryBot.define do
  factory :material_list do
    association :project
    association :author, factory: [:user, :constructor]
    name { "Lista de materiales" }
    source_type { :manual }
    status { :draft }

    transient do
      add_default_item { true }
    end

    after(:build) do |list, evaluator|
      if evaluator.add_default_item && list.material_items.empty?
        list.material_items << build(:material_item, material_list: list)
      end
    end
  end
end
