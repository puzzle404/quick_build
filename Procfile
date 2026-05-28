release: bundle exec rails db:migrate db:migrate:cache db:migrate:queue db:migrate:cable
web: bundle exec puma -C config/puma.rb
worker: bin/jobs
