# check-prerequisites.ps1 - Check Windows prerequisites
Write-Host "Checking prerequisites..."
try { docker --version; Write-Host "  [OK] Docker" -ForegroundColor Green } catch { Write-Host "  [MISSING] Docker" -ForegroundColor Red }
try { docker compose version; Write-Host "  [OK] Docker Compose" -ForegroundColor Green } catch { Write-Host "  [MISSING] Docker Compose" -ForegroundColor Red }
try { git --version; Write-Host "  [OK] Git" -ForegroundColor Green } catch { Write-Host "  [MISSING] Git" -ForegroundColor Red }
try { docker info 2>$null | Out-Null; Write-Host "  [OK] Docker daemon running" -ForegroundColor Green } catch { Write-Host "  [WARN] Docker not running. Start Docker Desktop." -ForegroundColor Yellow }