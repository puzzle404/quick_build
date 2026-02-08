# frozen_string_literal: true

module Ui
  class StatsSectionComponent < ViewComponent::Base
    def initialize(
      title: "Plataforma líder en gestión de construcción",
      subtitle: "Miles de profesionales confían en Quick Build"
    )
      @title = title
      @subtitle = subtitle
    end

    def stats
      [
        {
          value: "+2,500",
          label: "Proyectos gestionados",
          icon: "building",
          color: "indigo"
        },
        {
          value: "+500",
          label: "Constructores activos",
          icon: "users",
          color: "emerald"
        },
        {
          value: "+1M",
          label: "Materiales vendidos",
          icon: "cube",
          color: "amber"
        },
        {
          value: "99.9%",
          label: "Disponibilidad",
          icon: "check",
          color: "sky"
        }
      ]
    end
  end
end
