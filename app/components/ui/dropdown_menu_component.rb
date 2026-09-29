# frozen_string_literal: true

module Ui
  class DropdownMenuComponent < ViewComponent::Base
    def initialize(aria_label: 'Abrir menú', anchor: 'bottom end', button_class: nil, menu_class: nil)
      @aria_label = aria_label
      @anchor = anchor
      @button_class = button_class
      @menu_class = menu_class
    end

    private

    attr_reader :aria_label, :anchor, :button_class, :menu_class

    def default_button_classes
      "inline-flex justify-center rounded-md bg-white p-2 text-sm font-semibold text-gray-900 shadow-xs inset-ring-1 inset-ring-gray-300 hover:bg-gray-50"
    end

    def default_menu_classes
      "w-56 origin-top-right rounded-md bg-white shadow-lg outline-1 outline-black/5 transition transition-discrete [--anchor-gap:--spacing(2)] data-closed:scale-95 data-closed:transform data-closed:opacity-0 data-enter:duration-100 data-enter:ease-out data-leave:duration-75 data-leave:ease-in"
    end
  end
end

