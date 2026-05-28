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

    trait :with_stage do
      after(:build) do |list|
        list.project_stage ||= build(:project_stage, project: list.project)
      end
    end
  end
end
