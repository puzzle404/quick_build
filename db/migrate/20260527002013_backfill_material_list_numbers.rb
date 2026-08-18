class BackfillMaterialListNumbers < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    say_with_time "Backfilling material_lists.number per project" do
      execute <<~SQL
        WITH numbered AS (
          SELECT id,
                 ROW_NUMBER() OVER (PARTITION BY project_id ORDER BY created_at, id) AS rn
          FROM material_lists
          WHERE number IS NULL
        )
        UPDATE material_lists ml
        SET number = numbered.rn
        FROM numbered
        WHERE ml.id = numbered.id;
      SQL
    end
  end

  def down
    # No-op: dejar los valores backfilleados en lugar de volverlos a nil.
  end
end
