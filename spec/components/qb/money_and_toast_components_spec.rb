# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Qb money field + toasts", type: :component do
  describe Qb::MoneyFieldComponent do
    it "renderiza el prefijo de moneda y engancha la máscara es-AR" do
      form = ActionView::Helpers::FormBuilder.new(:expense, Expense.new, vc_test_controller.view_context, {})
      render_inline(Qb::MoneyFieldComponent.new(form: form, method: :amount_pesos, value: "1.500,50", required: true))

      expect(page).to have_css(".qb-money .qb-money-currency", text: "$")
      input = page.find("input[name='expense[amount_pesos]']")
      expect(input[:value]).to eq("1.500,50")
      expect(input[:inputmode]).to eq("decimal")
      expect(input[:"data-controller"]).to eq("qb--money-input")
      expect(input[:required]).to be_present
    end

    it "no necesita getter del atributo virtual en el modelo cuando no hay valor" do
      form = ActionView::Helpers::FormBuilder.new(:expense, Expense.new, vc_test_controller.view_context, {})

      expect { render_inline(Qb::MoneyFieldComponent.new(form: form, method: :amount_pesos)) }.not_to raise_error
    end
  end

  describe Qb::ToastStackComponent do
    it "muestra notice y alert como toasts con el tono correcto" do
      render_inline(described_class.new(notice: "Etapa creada", alert: "No pudimos borrar"))

      expect(page).to have_css("#qb_toasts .qb-toast--ok[role=status]", text: "Etapa creada")
      expect(page).to have_css("#qb_toasts .qb-toast--bad[role=alert]", text: "No pudimos borrar")
    end

    it "deja el contenedor vacío aunque no haya flash (para turbo_stream.append)" do
      render_inline(described_class.new)

      expect(page).to have_css("#qb_toasts", visible: :all)
      expect(page).to have_no_css(".qb-toast")
    end
  end
end
