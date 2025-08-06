# frozen_string_literal: true

# Sample categories
["Electrónica", "Libros", "Ropa"].each do |name|
  Category.find_or_create_by!(name: name)
end

# Sample company required for products
company = Company.find_or_create_by!(email: "demo@example.com") do |c|
  c.name = "Demo Company"
  c.password = "password"
end

# Sample products
[
  { name: "Laptop", price_cents: 100_000, description: "Portátil potente" },
  { name: "Libro de Ruby", price_cents: 3_000, description: "Aprende Ruby on Rails" },
  { name: "Camiseta", price_cents: 2_000, description: "Camiseta de algodón" }
].each do |attrs|
  Product.find_or_create_by!(name: attrs[:name], company: company) do |product|
    product.price_cents = attrs[:price_cents]
    product.description = attrs[:description]
  end
end
