# Canvas LMS Docker Deployment Guide (English)

> Complete guide to deploying Canvas LMS locally using Docker on any platform.

---

## Table of Contents

1. [Overview](#overview)
2. [System Requirements](#system-requirements)
3. [Prerequisites Installation](#prerequisites-installation)
4. [Quick Start](#quick-start)
5. [Detailed Setup Steps](#detailed-setup-steps)
6. [Configuration](#configuration)
7. [Architecture](#architecture)
8. [Usage Guide](#usage-guide)
9. [Troubleshooting](#troubleshooting)
10. [FAQ](#faq)

---

## Overview

Canvas LMS is an open-source Learning Management System developed by Instructure. This toolkit automates the Docker-based deployment process, making it easy to run Canvas LMS on your local machine for development, testing, or educational purposes.

### What Gets Deployed

- **Canvas LMS Web Server** (Ruby on Rails + Nginx + Passenger)
- **Background Jobs Worker** (Delayed Jobs)
- **PostgreSQL 12 with PostGIS 2.5** (Database)
- **Redis Alpine** (Cache & Message Queue)

---

## System Requirements

### Minimum Requirements

| Component | Requirement |
|-----------|-------------|
| OS | Windows 10/11, Ubuntu 20.04+, macOS 12+ |
| CPU | 4 cores recommended |
| RAM | 8 GB minimum, 16 GB recommended |
| Disk | 30 GB free space minimum |
| Network | Internet connection for initial setup |

### Docker Resource Allocation

Allocate the following resources in Docker Desktop/Engine settings:

- **Memory**: 8 GB (minimum) / 12 GB (recommended)
- **CPU**: 4 cores
- **Disk**: 60 GB
- **Swap**: 1 GB

---

## Prerequisites Installation

### Windows

#### Step 1: Install Docker Desktop

1. Download from: https://www.docker.com/products/docker-desktop/
2. Run the installer
3. Enable WSL 2 backend during installation
4. Restart your computer
5. Open Docker Desktop and wait for it to start

Verify:
```powershell
docker --version
docker compose version
```

#### Step 2: Install Git

1. Download from: https://git-scm.com/download/win
2. Run the installer with default settings

Verify:
```powershell
git --version
```

#### Step 3: (China Users) Configure Docker Mirror

If you cannot access Docker Hub directly:

1. Open Docker Desktop -> Settings -> Docker Engine
2. Add registry mirrors:
```json
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.xuanyuan.me",
    "https://docker.m.daocloud.io"
  ]
}
```
3. Click "Apply & Restart"

---

### Ubuntu / Debian Linux

#### Step 1: Install Docker Engine

```bash
# Remove old versions
sudo apt-get remove docker docker-engine docker.io containerd runc

# Set up repository
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

Verify:
```bash
docker --version
docker compose version
```

#### Step 2: Install Git

```bash
sudo apt-get install -y git
git --version
```

#### Step 3: (China Users) Configure Docker Mirror

```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.xuanyuan.me",
    "https://docker.m.daocloud.io"
  ]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

---

### macOS

#### Step 1: Install Docker Desktop

1. Download from: https://www.docker.com/products/docker-desktop/
2. Choose Apple Silicon (M1/M2/M3) or Intel based on your Mac
3. Drag to Applications folder
4. Launch Docker Desktop

Verify:
```bash
docker --version
docker compose version
```

#### Step 2: Install Git (via Xcode CLI tools)

```bash
xcode-select --install
```

---

## Quick Start

### One-Command Setup

**Windows:**
```powershell
git clone https://github.com/your-org/canvas-lms-setup.git
cd canvas-lms-setup
.\setup.ps1 -InstallPath "E:\Canvas LMS"
```

**Linux/macOS:**
```bash
git clone https://github.com/your-org/canvas-lms-setup.git
cd canvas-lms-setup
chmod +x setup.sh
./setup.sh --install-path /opt/canvas-lms
```

---

## Detailed Setup Steps

### Step 1: Clone Canvas LMS Repository

```bash
# Official repository (may be slow in China)
git clone https://github.com/instructure/canvas-lms.git

# China mirror (recommended for China users)
git clone https://gitee.com/xiong-yuhui/canvas-Lms.git canvas-lms
```

### Step 2: Apply Dockerfile Patches

The original Dockerfile may have build issues with expired GPG keys and deprecated repositories. Apply our patches:

```bash
# Copy our patched config files
cp configs/docker-compose.override.yml canvas-lms/
cp configs/database.yml canvas-lms/config/
cp configs/domain.yml canvas-lms/config/
cp configs/security.yml canvas-lms/config/
```

### Step 3: Configure Environment

Create `.env` file in the canvas-lms directory:

```bash
# Linux/macOS
echo "COMPOSE_FILE=docker-compose.yml:docker-compose.override.yml" > canvas-lms/.env

# Windows PowerShell
"COMPOSE_FILE=docker-compose.yml;docker-compose.override.yml" | Out-File canvas-lms/.env
```

### Step 4: Pull Docker Images

```bash
# Standard pull (if Docker Hub is accessible)
docker pull instructure/ruby-passenger:2.7
docker pull postgis/postgis:12-2.5
docker pull redis:alpine

# China mirror pull
docker pull docker.1ms.run/instructure/ruby-passenger:2.7
docker tag docker.1ms.run/instructure/ruby-passenger:2.7 instructure/ruby-passenger:2.7

docker pull docker.1ms.run/postgis/postgis:12-2.5
docker tag docker.1ms.run/postgis/postgis:12-2.5 postgis/postgis:12-2.5

docker pull docker.1ms.run/library/redis:alpine
docker tag docker.1ms.run/library/redis:alpine redis:alpine
```

### Step 5: Build and Start

```bash
cd canvas-lms
docker compose -f docker-compose.yml -f docker-compose.override.yml build
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d
```

### Step 6: Initialize Database

```bash
# Wait for postgres to be ready
docker compose exec postgres pg_isready -U canvas

# Run database migrations
docker compose exec web bundle exec rake db:create
docker compose exec web bundle exec rake db:initial_setup
docker compose exec web bundle exec rake db:migrate
```

### Step 7: Access Canvas LMS

Open your browser and navigate to: **http://localhost:3000**

Default admin account will be created during `db:initial_setup`.

---

## Configuration

### docker-compose.override.yml

Key configuration options in the override file:

```yaml
services:
  web:
    ports:
      - "3000:80"        # Change left port to use different host port
    environment:
      RAILS_ENV: development
    volumes:
      - .:/usr/src/app   # Mount source code for development

  postgres:
    ports:
      - "5432:5432"      # Expose PostgreSQL port

  redis:
    ports:
      - "6379:6379"      # Expose Redis port
```

### database.yml

```yaml
development:
  adapter: postgresql
  encoding: utf8
  database: canvas_development
  host: postgres          # Docker service name
  username: canvas
  password: sekret
  timeout: 5000
```

### domain.yml

```yaml
development:
  domain: localhost       # Change if using custom domain
```

---

## Architecture

### Service Topology

```
                    +-------------------+
                    |    Load Balancer   |
                    |    (localhost)     |
                    +--------+----------+
                             |
                    +--------v----------+
                    |   Web Container    |
                    | Nginx + Passenger  |
                    | Ruby on Rails 6.x  |
                    | Port: 3000 -> 80   |
                    +---+----------+----+
                        |          |
              +---------v--+  +---v---------+
              | PostgreSQL  |  |    Redis     |
              | + PostGIS   |  |   (Cache)    |
              | Port: 5432  |  | Port: 6379   |
              +-------------+  +--------------+
                        |
              +---------v----------+
              |   Jobs Container   |
              |  Delayed Jobs      |
              |  Background Worker |
              +--------------------+
```

### Technology Stack

| Layer | Technology |
|-------|-----------|
| Web Framework | Ruby on Rails 6.x |
| Ruby Version | 2.7 |
| Web Server | Nginx + Phusion Passenger |
| Database | PostgreSQL 12 + PostGIS 2.5 |
| Cache | Redis (Alpine) |
| Frontend | Node.js 14 + Yarn + Webpack |
| Bundler | 2.2.17 |
| Container | Docker + Docker Compose |

---

## Usage Guide

### Starting Canvas LMS

```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d
```

### Stopping Canvas LMS

```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml down
```

### Viewing Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f web
docker compose logs -f jobs
docker compose logs -f postgres
```

### Running Rails Console

```bash
docker compose exec web bundle exec rails console
```

### Running Database Migrations

```bash
docker compose exec web bundle exec rake db:migrate
```

### Rebuilding After Changes

```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml build --no-cache
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d
```

### Creating an Admin User

```bash
docker compose exec web bundle exec rails console
# Inside console:
# u = User.create!(name: "Admin", email: "admin@example.com", password: "password123")
# u.pseudonyms.create!(unique_id: "admin@example.com", password: "password123", password_confirmation: "password123")
# u.account_users.create!(account: Account.default, role: Role.default_account_role)
```

---

## Troubleshooting

### Build Fails: GPG Key Expired

**Error:** `The repository ... is not signed`

**Fix:** Our patched Dockerfile handles this by importing fresh keys:
```bash
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys D870AB033FB45BD1
```

### Build Fails: Repository No Release File

**Error:** `does not have a Release file`

**Fix:** Add `[trusted=yes]` to the repository line and wrap update with `|| true`:
```dockerfile
echo "deb [trusted=yes] http://apt.postgresql.org/pub/repos/apt/ focal-pgdg main"
RUN ... && (apt-get update -qq || true) && ...
```

### Docker Hub Unreachable (China)

**Fix:** Use mirror registries:
```bash
docker pull docker.1ms.run/instructure/ruby-passenger:2.7
docker tag docker.1ms.run/instructure/ruby-passenger:2.7 instructure/ruby-passenger:2.7
```

### Port Already in Use

**Fix:** Change the port mapping in `docker-compose.override.yml`:
```yaml
web:
  ports:
    - "8080:80"  # Use port 8080 instead of 3000
```

### Out of Memory

**Fix:** Increase Docker Desktop memory allocation to 12+ GB.

### Database Connection Failed

**Fix:** Ensure postgres container is healthy:
```bash
docker compose ps
docker compose logs postgres
```

---

## FAQ

**Q: How long does the initial build take?**
A: Approximately 15-30 minutes depending on network speed and hardware.

**Q: Can I use this for production?**
A: This setup is designed for development/testing. For production, additional security hardening is required.

**Q: How do I update Canvas LMS?**
A: Pull the latest code and rebuild:
```bash
git pull origin master
docker compose build
docker compose up -d
docker compose exec web bundle exec rake db:migrate
```

**Q: Can I run multiple Canvas instances?**
A: Yes, use different project names and port mappings:
```bash
docker compose -p canvas2 -f docker-compose.yml -f docker-compose.override.yml up -d
```