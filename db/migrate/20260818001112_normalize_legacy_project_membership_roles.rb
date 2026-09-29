class NormalizeLegacyProjectMembershipRoles < ActiveRecord::Migration[8.0]
  # `enum :role, [:viewer, :editor, :admin]` era POSICIONAL sobre una columna
  # string: Rails escribía "0"/"1"/"2" y al releer devolvía nil, así que ningún
  # rol sobrevivía al round-trip y las membresías parecían vacías.
  #
  # El enum ya guarda el label; esto normaliza las filas viejas para que
  # `.role` deje de devolver nil y no dependamos del mapeo legacy en runtime.
  # La traducción es la inversa exacta de lo que escribía el código anterior.
  LEGACY = { "0" => "viewer", "1" => "editor", "2" => "admin" }.freeze

  def up
    LEGACY.each do |numeric, label|
      execute <<~SQL.squish
        UPDATE project_memberships SET role = '#{label}' WHERE role = '#{numeric}'
      SQL
    end

    # Sin rol asignable no hay decisión de permisos posible: el más restrictivo.
    execute <<~SQL.squish
      UPDATE project_memberships SET role = 'viewer' WHERE role IS NULL OR role = ''
    SQL
  end

  def down
    LEGACY.each do |numeric, label|
      execute <<~SQL.squish
        UPDATE project_memberships SET role = '#{numeric}' WHERE role = '#{label}'
      SQL
    end
  end
end
