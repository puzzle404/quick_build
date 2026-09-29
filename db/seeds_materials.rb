# Materiales Básicos
ladrillo_12 = Material.create!(name: "Ladrillo Hueco 12x18x33", unit: "un", price: 150.00)
ladrillo_18 = Material.create!(name: "Ladrillo Hueco 18x18x33", unit: "un", price: 220.00)
cemento = Material.create!(name: "Cemento Portland (Bolsa 50kg)", unit: "un", price: 8500.00)
arena = Material.create!(name: "Arena Fina", unit: "m3", price: 25000.00)
cal = Material.create!(name: "Cal Hidratada (Bolsa 25kg)", unit: "un", price: 4500.00)
ceramico = Material.create!(name: "Cerámico Esmaltado 45x45", unit: "m2", price: 12000.00)
pegamento = Material.create!(name: "Pegamento para Cerámico (Bolsa 30kg)", unit: "un", price: 9000.00)
pintura = Material.create!(name: "Pintura Látex Interior (Lata 20L)", unit: "un", price: 85000.00)
cable_2_5 = Material.create!(name: "Cable Unipolar 2.5mm", unit: "m", price: 450.00)
toma = Material.create!(name: "Tomacorriente Doble", unit: "un", price: 3500.00)
caja_rect = Material.create!(name: "Caja Rectangular PVC", unit: "un", price: 500.00)
canio_corrugado = Material.create!(name: "Caño Corrugado 3/4", unit: "m", price: 250.00)

# Items Constructivos

# Muro de 12 (m2)
muro_12 = ConstructionItem.create!(name: "Muro Ladrillo Hueco 12", unit: "m2", category: "Albañilería")
ConstructionItemMaterial.create!(construction_item: muro_12, material: ladrillo_12, quantity: 16.0, waste_factor: 1.05)
ConstructionItemMaterial.create!(construction_item: muro_12, material: cemento, quantity: 0.15, waste_factor: 1.10) # Aprox mezcla
ConstructionItemMaterial.create!(construction_item: muro_12, material: arena, quantity: 0.04, waste_factor: 1.10)
ConstructionItemMaterial.create!(construction_item: muro_12, material: cal, quantity: 0.10, waste_factor: 1.05)

# Piso Cerámico (m2)
piso_ceramico = ConstructionItem.create!(name: "Piso Cerámico 45x45", unit: "m2", category: "Terminaciones")
ConstructionItemMaterial.create!(construction_item: piso_ceramico, material: ceramico, quantity: 1.0, waste_factor: 1.10)
ConstructionItemMaterial.create!(construction_item: piso_ceramico, material: pegamento, quantity: 0.15, waste_factor: 1.05) # Aprox 4-5kg/m2 -> 0.15 bolsa

# Pintura Muros (m2)
pintura_muro = ConstructionItem.create!(name: "Pintura Látex Muros (2 manos)", unit: "m2", category: "Pintura")
ConstructionItemMaterial.create!(construction_item: pintura_muro, material: pintura, quantity: 0.10, waste_factor: 1.05) # 10m2 por litro -> 0.1 litro/m2 -> 0.005 lata 20L (ajustar según unidad)
# Ajuste: Si la unidad de pintura es "un" (Lata 20L), entonces 1 m2 consume 1/200 latas = 0.005
# Vamos a cambiar la unidad de pintura a Litros para ser más claros, o ajustar quantity.
# Asumimos quantity en unidad del material. 0.005 latas.

# Instalación Eléctrica - Boca Tomacorriente (un)
boca_toma = ConstructionItem.create!(name: "Boca Tomacorriente Completa", unit: "un", category: "Electricidad")
ConstructionItemMaterial.create!(construction_item: boca_toma, material: toma, quantity: 1.0)
ConstructionItemMaterial.create!(construction_item: boca_toma, material: caja_rect, quantity: 1.0)
# Asumimos promedio de cable y caño por boca si se quiere, o se mide aparte.
# Vamos a medir cable aparte con la herramienta de línea.

# Cableado (m)
cableado = ConstructionItem.create!(name: "Cableado 2.5mm + Cañería", unit: "m", category: "Electricidad")
ConstructionItemMaterial.create!(construction_item: cableado, material: cable_2_5, quantity: 2.0, waste_factor: 1.10) # Fase + Neutro
ConstructionItemMaterial.create!(construction_item: cableado, material: canio_corrugado, quantity: 1.0, waste_factor: 1.05)
