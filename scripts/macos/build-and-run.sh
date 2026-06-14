#!/bin/bash
# build-and-run.sh
set -euo pipefail
cd "$1"
docker compose -f docker-compose.yml -f docker-compose.override.yml build
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d
echo "Waiting for PostgreSQL..."
sleep 15
docker compose exec -T postgres pg_isready -U canvas
docker compose exec -T web bundle exec rake db:create
docker compose exec -T web bundle exec rake db:initial_setup
docker compose exec -T web bundle exec rake db:migrate
echo "Canvas LMS ready at http://localhost:3000"