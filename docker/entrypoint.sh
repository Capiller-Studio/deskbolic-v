#!/bin/bash
set -e

# Remove any pre-existing PID files that could prevent servers from starting
rm -f /rails/tmp/pids/server.pid /rails/tmp/pids/sidekiq.pid /rails/tmp/pids/anycable.pid

# Run migrations and seed data only when RUN_MIGRATIONS is true
if [ "$RUN_MIGRATIONS" = "true" ]; then
  echo "==> Preparing primary database and running migrations..."
  bundle exec rails db:prepare || true

  echo "==> Running regional shard migrations..."
  bundle exec rails db:migrate:de || true

  if [ "$RUN_SEEDS" = "true" ]; then
    echo "==> Running initial seeds..."
    bundle exec rails db:seed || true
  fi
fi

exec "$@"
