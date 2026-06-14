#!/bin/bash
# check-prerequisites.sh
echo "Checking prerequisites..."
command -v docker >/dev/null 2>&1 && echo "  [OK] Docker: $(docker --version)" || echo "  [MISSING] Docker"
docker compose version >/dev/null 2>&1 && echo "  [OK] Compose: $(docker compose version)" || echo "  [MISSING] Compose"
command -v git >/dev/null 2>&1 && echo "  [OK] Git: $(git --version)" || echo "  [MISSING] Git"
docker info >/dev/null 2>&1 && echo "  [OK] Docker daemon running" || echo "  [WARN] Docker not running"