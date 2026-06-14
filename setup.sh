#!/usr/bin/env bash
# ============================================
# Canvas LMS One-Click Setup Script
# For Linux (Ubuntu/Debian) and macOS
# ============================================

set -euo pipefail

# ============================================
# Configuration
# ============================================
INSTALL_PATH=""
USE_MIRROR=false
PORT=3000
CANVAS_REPO="https://github.com/instructure/canvas-lms.git"
CANVAS_MIRROR="https://gitee.com/xiong-yuhui/canvas-Lms.git"
DOCKER_MIRROR="docker.1ms.run"
RUBY_IMAGE="instructure/ruby-passenger:2.7"
POSTGIS_IMAGE="postgis/postgis:12-2.5"
REDIS_IMAGE="redis:alpine"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m'

log_step()  { echo -e "\n${CYAN}>> $1${NC}"; }
log_ok()    { echo -e "  ${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "  ${YELLOW}[WARN]${NC} $1"; }
log_err()   { echo -e "  ${RED}[ERROR]${NC} $1"; }
log_info()  { echo -e "  ${GRAY}[INFO]${NC} $1"; }

# ============================================
# Parse Arguments
# ============================================
usage() {
    echo "Usage: $0 --install-path <path> [--mirror] [--port <port>]"
    echo ""
    echo "Options:"
    echo "  --install-path  Directory to install Canvas LMS (required)"
    echo "  --mirror        Use China Docker mirror (recommended for China users)"
    echo "  --port          Host port for Canvas LMS (default: 3000)"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --install-path /opt/canvas-lms"
    echo "  $0 --install-path ~/canvas --mirror --port 8080"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --install-path) INSTALL_PATH="$2"; shift 2 ;;
        --mirror)       USE_MIRROR=true; shift ;;
        --port)         PORT="$2"; shift 2 ;;
        --help)         usage ;;
        *)              echo "Unknown option: $1"; usage ;;
    esac
done

if [[ -z "$INSTALL_PATH" ]]; then
    log_err "Missing required --install-path argument"
    usage
fi

# Detect OS
OS_TYPE="unknown"
case "$(uname -s)" in
    Linux*)     OS_TYPE="linux" ;;
    Darwin*)    OS_TYPE="macos" ;;
    *)          OS_TYPE="unknown" ;;
esac

echo ""
echo "============================================"
echo "  Canvas LMS One-Click Setup"
echo "  OS: $OS_TYPE | Port: $PORT | Mirror: $USE_MIRROR"
echo "============================================"
echo ""

# ============================================
# Step 1: Check Prerequisites
# ============================================
check_prerequisites() {
    log_step "Step 1: Checking prerequisites..."

    # Check Docker
    if command -v docker &> /dev/null; then
        log_ok "Docker found: $(docker --version)"
    else
        log_err "Docker is not installed."
        if [[ "$OS_TYPE" == "linux" ]]; then
            log_info "Install Docker: https://docs.docker.com/engine/install/"
            log_info "Or run: sudo apt-get install docker.io docker-compose-plugin"
        elif [[ "$OS_TYPE" == "macos" ]]; then
            log_info "Download Docker Desktop: https://www.docker.com/products/docker-desktop/"
        fi
        exit 1
    fi

    # Check Docker Compose
    if docker compose version &> /dev/null; then
        log_ok "Docker Compose found: $(docker compose version)"
    elif command -v docker-compose &> /dev/null; then
        log_ok "docker-compose found: $(docker-compose --version)"
        # Create alias function
        docker() {
            if [[ "$1" == "compose" ]]; then
                shift
                command docker-compose "$@"
            else
                command docker "$@"
            fi
        }
    else
        log_err "Docker Compose is not available."
        exit 1
    fi

    # Check Docker daemon
    if docker info &> /dev/null; then
        log_ok "Docker daemon is running"
    else
        log_err "Docker daemon is not running."
        if [[ "$OS_TYPE" == "linux" ]]; then
            log_info "Start Docker: sudo systemctl start docker"
        elif [[ "$OS_TYPE" == "macos" ]]; then
            log_info "Please start Docker Desktop application."
        fi
        exit 1
    fi

    # Check Git
    if command -v git &> /dev/null; then
        log_ok "Git found: $(git --version)"
    else
        log_err "Git is not installed."
        if [[ "$OS_TYPE" == "linux" ]]; then
            log_info "Install: sudo apt-get install git"
        elif [[ "$OS_TYPE" == "macos" ]]; then
            log_info "Install: xcode-select --install"
        fi
        exit 1
    fi

    # Check available memory
    if [[ "$OS_TYPE" == "linux" ]]; then
        TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
        if [[ $TOTAL_MEM -lt 8 ]]; then
            log_warn "System has ${TOTAL_MEM}GB RAM. 8GB+ recommended."
        else
            log_ok "Memory: ${TOTAL_MEM}GB"
        fi
    fi
}

# ============================================
# Step 2: Clone Canvas LMS
# ============================================
clone_canvas() {
    log_step "Step 2: Cloning Canvas LMS repository..."

    CANVAS_DIR="$INSTALL_PATH/canvas-lms"

    if [[ -d "$CANVAS_DIR" ]]; then
        log_warn "Directory already exists: $CANVAS_DIR"
        log_info "Skipping clone. Using existing repository."
        return
    fi

    mkdir -p "$INSTALL_PATH"

    if [[ "$USE_MIRROR" == true ]]; then
        log_info "Using Gitee mirror (China)..."
        git clone "$CANVAS_MIRROR" "$CANVAS_DIR"
    else
        log_info "Using official GitHub repository..."
        git clone "$CANVAS_REPO" "$CANVAS_DIR"
    fi

    if [[ $? -ne 0 ]]; then
        log_err "Failed to clone repository."
        if [[ "$USE_MIRROR" != true ]]; then
            log_info "Try using --mirror flag for China mirror."
        fi
        exit 1
    fi

    log_ok "Canvas LMS cloned successfully"
}

# ============================================
# Step 3: Apply Dockerfile Patches
# ============================================
apply_patches() {
    log_step "Step 3: Applying Dockerfile patches..."

    local dockerfile="$CANVAS_DIR/Dockerfile"

    # Fix 1: Add [trusted=yes] to nodesource repo
    sed -i 's|echo "deb https://deb.nodesource.com|echo "deb [trusted=yes] https://deb.nodesource.com|g' "$dockerfile"

    # Fix 2: Add [trusted=yes] to pgdg repo
    sed -i 's|echo "deb http://apt.postgresql.org|echo "deb [trusted=yes] http://apt.postgresql.org|g' "$dockerfile"

    # Fix 3: Add GPG key import if not present
    if ! grep -q "D870AB033FB45BD1" "$dockerfile"; then
        sed -i 's|RUN apt-get update|RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys D870AB033FB45BD1 1655A0AB68576280 2>/dev/null || true \&\& apt-get update|' "$dockerfile"
    fi

    # Fix 4: Allow apt-get update to fail gracefully for pgdg
    sed -i 's|apt-key add - \&\& apt-get update -qq \&\& apt-get install|apt-key add - \&\& (apt-get update -qq || true) \&\& apt-get install|g' "$dockerfile"

    log_ok "Dockerfile patched"

    # Fix postgres Dockerfile for Debian Buster archive
    local pg_dockerfile="$CANVAS_DIR/docker-compose/postgres/Dockerfile"
    if [[ -f "$pg_dockerfile" ]]; then
        if ! grep -q "archive.debian.org" "$pg_dockerfile"; then
            sed -i "/^FROM/a RUN sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list \&\& sed -i 's|security.debian.org|archive.debian.org/debian-security|g' /etc/apt/sources.list \&\& sed -i '/buster-updates/d' /etc/apt/sources.list \&\& echo 'Acquire::Check-Valid-Until \"false\";' > /etc/apt/apt.conf.d/99no-check-valid-until" "$pg_dockerfile"
        fi
        log_ok "Postgres Dockerfile patched"
    fi
}

# ============================================
# Step 4: Configure Canvas LMS
# ============================================
configure_canvas() {
    log_step "Step 4: Configuring Canvas LMS..."

    # docker-compose.override.yml
    cat > "$CANVAS_DIR/docker-compose.override.yml" << 'OVERRIDE'
services:
  web:
    environment:
      RAILS_ENV: development
    ports:
      - "PORT_PLACEHOLDER:80"
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
OVERRIDE
    sed -i "s/PORT_PLACEHOLDER/$PORT/g" "$CANVAS_DIR/docker-compose.override.yml"
    log_ok "docker-compose.override.yml created"

    # database.yml
    mkdir -p "$CANVAS_DIR/config"
    cat > "$CANVAS_DIR/config/database.yml" << 'DBYML'
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
DBYML
    log_ok "config/database.yml created"

    # domain.yml
    cat > "$CANVAS_DIR/config/domain.yml" << 'DOMYML'
development:
  domain: localhost
test:
  domain: localhost
DOMYML
    log_ok "config/domain.yml created"

    # security.yml
    ENC_KEY=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1)
    ENC_SECRET=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1)
    cat > "$CANVAS_DIR/config/security.yml" << SECYML
development:
  encryption_key: $ENC_KEY
  encryption_secret: $ENC_SECRET
test:
  encryption_key: test$ENC_KEY
  encryption_secret: test$ENC_SECRET
SECYML
    log_ok "config/security.yml created"
}

# ============================================
# Step 5: Pull Docker Images
# ============================================
pull_images() {
    log_step "Step 5: Pulling Docker images..."

    if [[ "$USE_MIRROR" == true ]]; then
        log_info "Using Docker mirror: $DOCKER_MIRROR"

        log_info "Pulling $RUBY_IMAGE via mirror..."
        docker pull "$DOCKER_MIRROR/$RUBY_IMAGE"
        docker tag "$DOCKER_MIRROR/$RUBY_IMAGE" "$RUBY_IMAGE"
        log_ok "$RUBY_IMAGE ready"

        log_info "Pulling $POSTGIS_IMAGE via mirror..."
        docker pull "$DOCKER_MIRROR/$POSTGIS_IMAGE"
        docker tag "$DOCKER_MIRROR/$POSTGIS_IMAGE" "$POSTGIS_IMAGE"
        log_ok "$POSTGIS_IMAGE ready"

        log_info "Pulling $REDIS_IMAGE via mirror..."
        docker pull "$DOCKER_MIRROR/library/$REDIS_IMAGE"
        docker tag "$DOCKER_MIRROR/library/$REDIS_IMAGE" "$REDIS_IMAGE"
        log_ok "$REDIS_IMAGE ready"
    else
        log_info "Pulling images from Docker Hub..."
        docker pull "$RUBY_IMAGE"
        docker pull "$POSTGIS_IMAGE"
        docker pull "$REDIS_IMAGE"
    fi
}

# ============================================
# Step 6: Build and Start
# ============================================
build_and_start() {
    log_step "Step 6: Building Docker images (this may take 15-30 minutes)..."

    cd "$CANVAS_DIR"

    docker compose -f docker-compose.yml -f docker-compose.override.yml build
    if [[ $? -ne 0 ]]; then
        log_err "Build failed. Check the output above for errors."
        exit 1
    fi
    log_ok "Build completed successfully!"

    log_step "Step 7: Starting services..."
    docker compose -f docker-compose.yml -f docker-compose.override.yml up -d
    if [[ $? -ne 0 ]]; then
        log_err "Failed to start services."
        exit 1
    fi
    log_ok "All services started!"

    # Wait for postgres
    log_step "Waiting for PostgreSQL to be ready..."
    local max_wait=60
    local waited=0
    while [[ $waited -lt $max_wait ]]; do
        if docker compose exec -T postgres pg_isready -U canvas &> /dev/null; then
            log_ok "PostgreSQL is ready!"
            break
        fi
        sleep 3
        waited=$((waited + 3))
        log_info "Waiting... ${waited}s"
    done

    if [[ $waited -ge $max_wait ]]; then
        log_warn "PostgreSQL took too long. Initialize database manually."
    else
        log_step "Step 8: Initializing database..."
        docker compose exec -T web bundle exec rake db:create
        docker compose exec -T web bundle exec rake db:initial_setup
        docker compose exec -T web bundle exec rake db:migrate
        log_ok "Database initialized!"
    fi
}

# ============================================
# Main
# ============================================
check_prerequisites
clone_canvas
apply_patches
configure_canvas
pull_images
build_and_start

echo ""
echo "============================================"
echo "  Canvas LMS Setup Complete!"
echo "============================================"
echo ""
echo "  Access Canvas LMS at: http://localhost:$PORT"
echo ""
echo "  Useful commands:"
echo "    cd $CANVAS_DIR"
echo "    View logs:     docker compose -f docker-compose.yml -f docker-compose.override.yml logs -f"
echo "    Stop:          docker compose -f docker-compose.yml -f docker-compose.override.yml down"
echo "    Start:         docker compose -f docker-compose.yml -f docker-compose.override.yml up -d"
echo "    Rails console: docker compose exec web bundle exec rails console"
echo ""