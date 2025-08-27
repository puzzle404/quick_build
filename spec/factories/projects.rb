FactoryBot.define do
  factory :project do
    association :constructor, factory: [:user, :constructor]
    name { "Sample Project" }
    location { "Sample City" }
    start_date { Date.today }
    end_date { Date.today + 30 }
    status { :planned }
    association :owner, factory: [:user, :constructor]
  end
end
