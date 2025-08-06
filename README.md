# QuickBuild

Aplicación de ejemplo construida con Rails 8.

## Requisitos

- Ruby 3.2 o superior
- PostgreSQL
- Bundler

## Instalación

1. Clonar el repositorio.
2. Instalar dependencias:
   ```bash
   bundle install
   ```
3. Preparar la base de datos:
   ```bash
   bin/rails db:setup
   ```
4. Cargar datos de ejemplo:
   ```bash
   bin/rails db:seed
   ```

## Comandos básicos

- Iniciar el servidor de desarrollo: `bin/dev`
- Ejecutar pruebas: `bundle exec rspec`
- Revisar estilo de código: `bundle exec rubocop`
