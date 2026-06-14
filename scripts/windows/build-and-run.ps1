# build-and-run.ps1
param([string]$CanvasDir)
Push-Location $CanvasDir
docker compose -f docker-compose.yml -f docker-compose.override.yml build
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d
Write-Host "Waiting for PostgreSQL..."
Start-Sleep 15
docker compose exec -T postgres pg_isready -U canvas
docker compose exec -T web bundle exec rake db:create
docker compose exec -T web bundle exec rake db:initial_setup
docker compose exec -T web bundle exec rake db:migrate
Write-Host "Canvas LMS ready at http://localhost:3000" -ForegroundColor Green
Pop-Location