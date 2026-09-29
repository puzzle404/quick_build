# frozen_string_literal: true

# El layout constructor trae un <template> con el esqueleto del drawer
# (Qb::DrawerSkeletonComponent), que incluye un `.qb-drawer-panel` inerte.
# Para preguntar "¿se renderizó un drawer?" hay que mirar el HTML sin los
# <template>, o toda página completa parecería un drawer.
module ResponseBodyHelpers
  def body_without_templates
    response.body.gsub(%r{<template\b.*?</template>}m, "")
  end
end

RSpec.configure do |config|
  config.include ResponseBodyHelpers, type: :request
end
