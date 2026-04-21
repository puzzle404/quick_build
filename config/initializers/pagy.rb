# frozen_string_literal: true

# Pagy · simple pagination for Quick Build OS
# https://ddnexus.github.io/pagy

require 'pagy'
require 'pagy/extras/array'

Pagy::DEFAULT[:limit] = 25
Pagy::DEFAULT[:size]  = 7 # how many page numbers to display in nav
