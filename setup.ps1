<#
.SYNOPSIS
    Canvas LMS One-Click Setup Script for Windows
.DESCRIPTION
    Automatically installs and configures Canvas LMS using Docker.
.PARAMETER InstallPath
    The directory where Canvas LMS will be installed.
.PARAMETER UseMirror
    Use China mirror for Docker images (recommended for China users).
.PARAMETER Port
    The host port for Canvas LMS web interface (default: 3000).
.EXAMPLE
    .\setup.ps1 -InstallPath "E:\Canvas LMS"
.EXAMPLE
    .\setup.ps1 -InstallPath "D:\canvas" -UseMirror -Port 8080
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$InstallPath,

    [switch]$UseMirror,

    [int]$Port = 3000
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ============================================
# Configuration
# ============================================
$CANVAS_REPO = "https://github.com/instructure/canvas-lms.git"
$CANVAS_MIRROR = "https://gitee.com/xiong-yuhui/canvas-Lms.git"
$DOCKER_MIRROR = "docker.1ms.run"
$RUBY_IMAGE = "instructure/ruby-passenger:2.7"
$POSTGIS_IMAGE = "postgis/postgis:12-2.5"
$REDIS_IMAGE = "redis:alpine"

# Colors
function Write-Step { param([string]$msg) Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Ok { param([string]$msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Err { param([string]$msg) Write-Host "  [ERROR] $msg" -ForegroundColor Red }
function Write-Info { param([string]$msg) Write-Host "  [INFO] $msg" -ForegroundColor Gray }

# ============================================
# Step 1: Check Prerequisites
# ============================================
function Test-Prerequisites {
    Write-Step "Step 1: Checking prerequisites..."

    # Check Docker
    try {
        $dockerVersion = docker --version 2>&1
        if ($LASTEXITCODE -ne 0) { throw }
        Write-Ok "Docker found: $dockerVersion"
    } catch {
        Write-Err "Docker is not installed or not running."
        Write-Info "Download Docker Desktop: https://www.docker.com/products/docker-desktop/"
        exit 1
    }

    # Check Docker Compose
    try {
        $composeVersion = docker compose version 2>&1
        if ($LASTEXITCODE -ne 0) { throw }
        Write-Ok "Docker Compose found: $composeVersion"
    } catch {
        Write-Err "Docker Compose v2 is not available."
        exit 1
    }

    # Check Docker daemon
    try {
        docker info 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw }
        Write-Ok "Docker daemon is running"
    } catch {
        Write-Err "Docker daemon is not running. Please start Docker Desktop."
        exit 1
    }

    # Check Git
    try {
        $gitVersion = git --version 2>&1
        if ($LASTEXITCODE -ne 0) { throw }
        Write-Ok "Git found: $gitVersion"
    } catch {
        Write-Err "Git is not installed."
        Write-Info "Download Git: https://git-scm.com/download/win"
        exit 1
    }
}

# ============================================
# Step 2: Clone Canvas LMS
# ============================================
function Get-CanvasSource {
    Write-Step "Step 2: Cloning Canvas LMS repository..."

    $canvasDir = Join-Path $InstallPath "canvas-lms"

    if (Test-Path $canvasDir) {
        Write-Warn "Directory already exists: $canvasDir"
        Write-Info "Skipping clone. Using existing repository."
        return $canvasDir
    }

    # Create install directory
    if (-not (Test-Path $InstallPath)) {
        New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
        Write-Ok "Created directory: $InstallPath"
    }

    if ($UseMirror) {
        Write-Info "Using Gitee mirror (China)..."
        git clone $CANVAS_MIRROR $canvasDir
    } else {
        Write-Info "Using official GitHub repository..."
        git clone $CANVAS_REPO $canvasDir
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Err "Failed to clone repository."
        if (-not $UseMirror) {
            Write-Info "Try using -UseMirror flag for China mirror."
        }
        exit 1
    }

    Write-Ok "Canvas LMS cloned successfully"
    return $canvasDir
}

# ============================================
# Step 3: Apply Dockerfile Patches
# ============================================
function Apply-Patches {
    param([string]$canvasDir)

    Write-Step "Step 3: Applying Dockerfile patches..."

    $dockerfilePath = Join-Path $canvasDir "Dockerfile"
    $content = [System.IO.File]::ReadAllText($dockerfilePath)

    # Fix 1: Add [trusted=yes] to nodesource repo
    $content = $content -replace 'echo "deb (https://deb\.nodesource\.com)', 'echo "deb [trusted=yes] $1'

    # Fix 2: Add [trusted=yes] to pgdg repo
    $content = $content -replace 'echo "deb (http://apt\.postgresql\.org)', 'echo "deb [trusted=yes] $1'

    # Fix 3: Import GPG keys before apt-get update
    if ($content -notmatch "keyserver.ubuntu.com.*D870AB033FB45BD1") {
        $content = $content -replace 'RUN (apt-get update)', 'RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys D870AB033FB45BD1 1655A0AB68576280 2>/dev/null || true && $1'
    }

    # Fix 4: Allow apt-get update to fail gracefully (for pgdg repo)
    $content = $content -replace 'apt-key add - && apt-get update -qq && apt-get install', 'apt-key add - && (apt-get update -qq || true) && apt-get install'

    [System.IO.File]::WriteAllText($dockerfilePath, $content, [System.Text.Encoding]::UTF8)
    Write-Ok "Dockerfile patched"

    # Fix postgres Dockerfile for Debian Buster archive
    $postgresDockerfile = Join-Path $canvasDir "docker-compose\postgres\Dockerfile"
    if (Test-Path $postgresDockerfile) {
        $pgContent = [System.IO.File]::ReadAllText($postgresDockerfile)
        if ($pgContent -notmatch "archive.debian.org") {
            $patchLine = "RUN sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list && sed -i 's|security.debian.org|archive.debian.org/debian-security|g' /etc/apt/sources.list && sed -i '/buster-updates/d' /etc/apt/sources.list && echo 'Acquire::Check-Valid-Until \"false\";' > /etc/apt/apt.conf.d/99no-check-valid-until"
            $pgContent = $pgContent -replace '(FROM [^\r\n]+)', "`$1`n$patchLine"
            [System.IO.File]::WriteAllText($postgresDockerfile, $pgContent, [System.Text.Encoding]::UTF8)
        }
        Write-Ok "Postgres Dockerfile patched"
    }
}

# ============================================
# Step 4: Configure Canvas LMS
# ============================================
function Set-CanvasConfig {
    param([string]$canvasDir)

    Write-Step "Step 4: Configuring Canvas LMS..."

    # docker-compose.override.yml
    $overrideYml = @"
services:
  web:
    environment:
      RAILS_ENV: development
    ports:
      - "${Port}:80"
    volumes:
      - .:/usr/src/app
    depends_on:
      - postgres
      - redis
  jobs:
    environment:
      RAILS_ENV: development
    volumes:
      - .:/usr/src/app
    depends_on:
      - postgres
      - redis
  postgres:
    ports:
      - "5432:5432"
  redis:
    ports:
      - "6379:6379"
"@
    [System.IO.File]::WriteAllText("$canvasDir\docker-compose.override.yml", $overrideYml, [System.Text.Encoding]::UTF8)
    Write-Ok "docker-compose.override.yml created"

    # database.yml
    $dbYml = @"
development:
  adapter: postgresql
  encoding: utf8
  database: canvas_development
  host: postgres
  username: canvas
  password: sekret
  timeout: 5000
test:
  adapter: postgresql
  encoding: utf8
  database: canvas_test
  host: postgres
  username: canvas
  password: sekret
  timeout: 5000
"@
    $configDir = Join-Path $canvasDir "config"
    if (-not (Test-Path $configDir)) { New-Item -Path $configDir -ItemType Directory -Force | Out-Null }
    [System.IO.File]::WriteAllText("$configDir\database.yml", $dbYml, [System.Text.Encoding]::UTF8)
    Write-Ok "config/database.yml created"

    # domain.yml
    $domainYml = @"
development:
  domain: localhost
test:
  domain: localhost
"@
    [System.IO.File]::WriteAllText("$configDir\domain.yml", $domainYml, [System.Text.Encoding]::UTF8)
    Write-Ok "config/domain.yml created"

    # security.yml
    $secYml = @"
development:
  encryption_key: $(New-Guid -ErrorAction SilentlyContinue | ForEach-Object { $_.ToString().Replace('-','').Substring(0,32) })
  encryption_secret: $(New-Guid -ErrorAction SilentlyContinue | ForEach-Object { $_.ToString().Replace('-','').Substring(0,32) })
test:
  encryption_key: test$(New-Guid -ErrorAction SilentlyContinue | ForEach-Object { $_.ToString().Replace('-','').Substring(0,28) })
  encryption_secret: test$(New-Guid -ErrorAction SilentlyContinue | ForEach-Object { $_.ToString().Replace('-','').Substring(0,28) })
"@
    [System.IO.File]::WriteAllText("$configDir\security.yml", $secYml, [System.Text.Encoding]::UTF8)
    Write-Ok "config/security.yml created"
}

# ============================================
# Step 5: Pull Docker Images
# ============================================
function Get-DockerImages {
    Write-Step "Step 5: Pulling Docker images..."

    if ($UseMirror) {
        Write-Info "Using Docker mirror: $DOCKER_MIRROR"

        # Ruby Passenger
        Write-Info "Pulling $RUBY_IMAGE via mirror..."
        docker pull "$DOCKER_MIRROR/$RUBY_IMAGE" 2>&1 | Out-Null
        docker tag "$DOCKER_MIRROR/$RUBY_IMAGE" $RUBY_IMAGE
        Write-Ok "$RUBY_IMAGE ready"

        # PostGIS
        Write-Info "Pulling $POSTGIS_IMAGE via mirror..."
        docker pull "$DOCKER_MIRROR/$POSTGIS_IMAGE" 2>&1 | Out-Null
        docker tag "$DOCKER_MIRROR/$POSTGIS_IMAGE" $POSTGIS_IMAGE
        Write-Ok "$POSTGIS_IMAGE ready"

        # Redis
        Write-Info "Pulling $REDIS_IMAGE via mirror..."
        docker pull "$DOCKER_MIRROR/library/$REDIS_IMAGE" 2>&1 | Out-Null
        docker tag "$DOCKER_MIRROR/library/$REDIS_IMAGE" $REDIS_IMAGE
        Write-Ok "$REDIS_IMAGE ready"
    } else {
        Write-Info "Pulling images from Docker Hub..."
        docker pull $RUBY_IMAGE
        docker pull $POSTGIS_IMAGE
        docker pull $REDIS_IMAGE
    }
}

# ============================================
# Step 6: Build and Start
# ============================================
function Build-AndStart {
    param([string]$canvasDir)

    Write-Step "Step 6: Building Docker images (this may take 15-30 minutes)..."

    Push-Location $canvasDir

    try {
        docker compose -f docker-compose.yml -f docker-compose.override.yml build 2>&1 | ForEach-Object {
            Write-Host $_
        }

        if ($LASTEXITCODE -ne 0) {
            Write-Err "Build failed. Check the output above for errors."
            exit 1
        }

        Write-Ok "Build completed successfully!"

        Write-Step "Step 7: Starting services..."
        docker compose -f docker-compose.yml -f docker-compose.override.yml up -d

        if ($LASTEXITCODE -ne 0) {
            Write-Err "Failed to start services."
            exit 1
        }

        Write-Ok "All services started!"

        # Wait for postgres
        Write-Step "Waiting for PostgreSQL to be ready..."
        $maxWait = 60
        $waited = 0
        while ($waited -lt $maxWait) {
            $result = docker compose exec -T postgres pg_isready -U canvas 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Ok "PostgreSQL is ready!"
                break
            }
            Start-Sleep -Seconds 3
            $waited += 3
            Write-Info "Waiting... ${waited}s"
        }

        if ($waited -ge $maxWait) {
            Write-Warn "PostgreSQL took too long to start. You may need to initialize the database manually."
        } else {
            Write-Step "Step 8: Initializing database..."
            docker compose exec -T web bundle exec rake db:create 2>&1 | ForEach-Object { Write-Host $_ }
            docker compose exec -T web bundle exec rake db:initial_setup 2>&1 | ForEach-Object { Write-Host $_ }
            docker compose exec -T web bundle exec rake db:migrate 2>&1 | ForEach-Object { Write-Host $_ }
            Write-Ok "Database initialized!"
        }

    } finally {
        Pop-Location
    }
}

# ============================================
# Main
# ============================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  Canvas LMS One-Click Setup for Windows" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
Write-Host ""
Write-Info "Install Path: $InstallPath"
Write-Info "Port: $Port"
Write-Info "Use Mirror: $UseMirror"

Test-Prerequisites
$canvasDir = Get-CanvasSource
Apply-Patches -canvasDir $canvasDir
Set-CanvasConfig -canvasDir $canvasDir
Get-DockerImages
Build-AndStart -canvasDir $canvasDir

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Canvas LMS Setup Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Access Canvas LMS at: http://localhost:$Port" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Useful commands:" -ForegroundColor Yellow
Write-Host "    View logs:    docker compose -f docker-compose.yml -f docker-compose.override.yml logs -f" -ForegroundColor White
Write-Host "    Stop:         docker compose -f docker-compose.yml -f docker-compose.override.yml down" -ForegroundColor White
Write-Host "    Start:        docker compose -f docker-compose.yml -f docker-compose.override.yml up -d" -ForegroundColor White
Write-Host "    Rails console: docker compose exec web bundle exec rails console" -ForegroundColor White
Write-Host ""