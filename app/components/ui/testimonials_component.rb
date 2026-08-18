# frozen_string_literal: true

module Ui
  class TestimonialsComponent < ViewComponent::Base
    def initialize(
      title: "Lo que dicen nuestros clientes",
      subtitle: "Constructores y proveedores que transformaron su negocio"
    )
      @title = title
      @subtitle = subtitle
    end

    def testimonials
      [
        {
          quote: "Quick Build transformó la forma en que gestionamos nuestros proyectos. Ahora tenemos visibilidad total de costos y tiempos en tiempo real.",
          author: "Martín García",
          role: "Director de Obras, Constructora Norte",
          avatar_initials: "MG",
          rating: 5
        },
        {
          quote: "El marketplace de materiales nos permite comparar precios al instante. Reducimos costos de compra en un 20% el primer año.",
          author: "Laura Fernández",
          role: "Gerente de Compras, Grupo Construir",
          avatar_initials: "LF",
          rating: 5
        },
        {
          quote: "La colaboración con nuestros clientes mejoró muchísimo. Pueden ver el avance de obra desde su celular sin molestarnos.",
          author: "Carlos Rodríguez",
          role: "Arquitecto, Studio CR",
          avatar_initials: "CR",
          rating: 5
        }
      ]
    end
  end
end
