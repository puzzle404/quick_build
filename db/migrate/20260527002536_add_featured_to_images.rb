class AddFeaturedToImages < ActiveRecord::Migration[8.0]
  def change
    add_column :images, :featured, :boolean, default: false, null: false
    add_index  :images, [ :imageable_type, :imageable_id ],
               unique: true,
               where: "featured",
               name: "index_images_unique_featured_per_imageable"
  end
end
