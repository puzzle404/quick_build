FactoryBot.define do
  factory :blueprint do
    association :project
    sequence(:name) { |n| "Plano #{n}" }

    # Blueprint valida presencia de :file y que sea JPG/PNG.
    after(:build) do |blueprint|
      unless blueprint.file.attached?
        blueprint.file.attach(
          io: StringIO.new("fake-bytes"),
          filename: "plano.png",
          content_type: "image/png"
        )
      end
    end

    trait :with_scale do
      scale_ratio { 100 }
    end

    trait :with_measurements do
      measurements do
        { "groups" => [ { "id" => "g1", "name" => "Muros", "type" => "line", "total_value" => 12.5, "unit" => "m" } ] }
      end
    end
  end
end
