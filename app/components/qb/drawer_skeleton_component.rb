# frozen_string_literal: true

# Contenido provisorio del drawer global mientras su frame carga (GET lento).
# Se renderiza una vez dentro de un <template> del layout y qb--drawer lo
# clona en el frame si la respuesta tarda más de ~200 ms.
class Qb::DrawerSkeletonComponent < ViewComponent::Base
  def call
    render(Qb::DrawerComponent.new(size: :lg)) do |d|
      d.with_custom_header do
        content_tag(:div, class: "qb-drawer-header", style: "align-items:center;") do
          safe_join([
            content_tag(:span, "", class: "qb-skeleton", style: "width:160px;height:12px;"),
            content_tag(:span, "", style: "flex:1;"),
            content_tag(:button, render(Qb::IconComponent.new(name: :x, size: 16)), type: "button", class: "qb-drawer-close",
                        data: { action: "click->qb--drawer#close" }, "aria-label": "Cerrar")
          ])
        end
      end
      # Bloques grandes arriba (la señal que se ve de lejos) y debajo el
      # esqueleto del form, tenue, que anticipa la forma de lo que viene.
      content_tag(:div, style: "display:flex;flex-direction:column;gap:12px;", "aria-busy": "true") do
        safe_join([
          content_tag(:div, render(Qb::SpinnerComponent.new(variant: :blocks, size: 32, label: "Cargando…")),
                      style: "display:flex;justify-content:center;padding:40px 0 32px;"),
          *[ [ "40%", 9 ], [ "100%", 32 ], [ "40%", 9 ], [ "100%", 32 ], [ "35%", 9 ], [ "100%", 64 ] ]
            .map { |w, h| content_tag(:span, "", class: "qb-skeleton", style: "width:#{w};height:#{h}px;opacity:.6;") }
        ])
      end
    end
  end
end
