# frozen_string_literal: true

# === SEED DATA ===
# This file populates the database with sample Categories, Companies, Products, and Users.
# Run with: rails db:seed

# --- Categories ---
categories = %w[
  Electrónica Libros Ropa Hogar Deportes Salud Belleza Juguetes
  Oficina Herramientas Jardín Cocina Automotriz Música Cine
  Videojuegos Tecnología Arte Viajes
]

categories.each do |name|
  Category.find_or_create_by!(name: name)
end

# --- Companies ---
companies_data = [
  { name: "Demo Company", email: "demo@example.com", password: "password" },
  { name: "Tech Corp",    email: "tech@corp.com",     password: "secure123" },
  { name: "Book World",   email: "info@bookworld.com", password: "readbooks" }
]

companies = companies_data.map do |attrs|
  Company.find_or_create_by!(email: attrs[:email]) do |company|
    company.name     = attrs[:name]
  end
end

# --- Products ---
product_samples = [
  { name: "Laptop Pro 15", price_cents: 1_200_00, description: "Portátil de alto rendimiento para profesionales." },
  { name: "Ruby on Rails Guide", price_cents: 4_500,    description: "Manual completo de Rails 7." },
  { name: "Camiseta Oficial", price_cents: 2_200,      description: "Algodón 100% con logo impreso." },
  { name: "Juego de Jardín",  price_cents: 3_800,      description: "Set de herramientas para jardín." },
  { name: "Auriculares A1",   price_cents: 6_500,      description: "Audio de alta fidelidad con cancelación de ruido." },
  { name: "Bicicleta MTB",    price_cents: 15_000,     description: "Mountain bike para rutas off-road." },
  { name: "Set de Tazas",     price_cents: 1_800,      description: "Juego de 4 tazas de cerámica." },
  { name: "Teclado Mecánico", price_cents: 8_200,      description: "Switches azules y retroiluminación RGB." },
  { name: "Smartwatch X2",    price_cents: 9_900,      description: "Monitor de salud y notificaciones." },
  { name: "Libro de Cocina",  price_cents: 2_900,      description: "Recetas fáciles y saludables." }
]

product_samples.each do |attrs|
  Product.find_or_create_by!(name: attrs[:name], company: companies.sample) do |product|
    product.price_cents  = attrs[:price_cents]
    product.description  = attrs[:description]
    product.category     = Category.order(Arel.sql('RANDOM()')).first
  end
end

# --- Optional: Create an admin user ---
  User.find_or_create_by!(email: 'admin@example.com') do |user|
    user.email     = Faker::Internet.unique.email(domain: 'example.com')
    user.password = 'adminpass'
    user.role     = 'admin' if
  User.find_or_create_by!(email: 'constructor@example.com') do |user|
    user.email     = 'constructor@example.com'
    user.password = 123456
    user.role     = 'constructor'
  end
end
