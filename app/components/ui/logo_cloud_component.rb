# frozen_string_literal: true

class Ui::LogoCloudComponent < ViewComponent::Base
  def initialize(title: "Confían en nosotros")
    @title = title
  end
  
  def companies
    [
      { name: "BuildTech", icon: "🏗️" },
      { name: "ProConstruye", icon: "🔨" },
      { name: "MateriaPro", icon: "📦" },
      { name: "ObrasMaster", icon: "🏢" },
      { name: "Constructora Plus", icon: "⚡" }
    ]
  end
end
