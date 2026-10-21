class AddBudgetCurrencyToProjects < ActiveRecord::Migration[8.0]
  # Moneda del presupuesto de la obra (ARS / USD). Lo gastado sigue en pesos:
  # para comparar se usa Project#budget_ars_cents (feedback 29/09).
  def change
    add_column :projects, :budget_currency, :string, null: false, default: "ARS"
  end
end
