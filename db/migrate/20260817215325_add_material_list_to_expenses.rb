class AddMaterialListToExpenses < ActiveRecord::Migration[8.0]
  # Vincula un gasto con la lista de materiales que lo originó ("marcar lista
  # como pagada"). Nullable: la mayoría de los gastos no vienen de una lista.
  # El estado "pagada" se deriva de la existencia de gastos — no hay columna
  # denormalizada que se pueda desincronizar al borrar un gasto.
  def change
    add_reference :expenses, :material_list, null: true, foreign_key: true
  end
end
