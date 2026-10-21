FactoryBot.define do
  factory :image do
    association :imageable, factory: :project

    after(:build) do |image|
      unless image.file.attached?
        image.file.attach(
          io: StringIO.new("fake-bytes"),
          filename: "photo.png",
          content_type: "image/png"
        )
      end
    end
  end
end
