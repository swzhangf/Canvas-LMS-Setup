# Canvas LMS One-Click Setup Toolkit

> Fully automated Canvas LMS deployment toolkit for Windows / Linux / macOS

## Language / 语言 / 言語

| Language | Document |
|----------|----------|
| English | [docs/README-en.md](docs/README-en.md) |
| 简体中文 | [docs/README-zh.md](docs/README-zh.md) |
| 日本語 | [docs/README-ja.md](docs/README-ja.md) |

## Quick Start

### Windows (PowerShell)
```powershell
git clone https://github.com/your-org/canvas-lms-setup.git
cd canvas-lms-setup
.\setup.ps1 -InstallPath "E:\Canvas LMS"
```

### Linux / macOS (Bash)
```bash
git clone https://github.com/your-org/canvas-lms-setup.git
cd canvas-lms-setup
chmod +x setup.sh
./setup.sh --install-path /opt/canvas-lms
```

## Prerequisites

| Requirement | Windows | Linux (Ubuntu/Debian) | macOS |
|------------|---------|----------------------|-------|
| Docker Desktop / Engine | Required | Required | Required (Docker Desktop) |
| Docker Compose v2 | Included in Docker Desktop | Install separately | Included in Docker Desktop |
| Git | Required | Required | Required |
| RAM | >= 8 GB | >= 8 GB | >= 8 GB |
| Disk Space | >= 30 GB | >= 30 GB | >= 30 GB |

## Architecture

```
canvas-lms-setup/
+-- setup.ps1                  # Windows auto-setup
+-- setup.sh                   # Linux/macOS auto-setup
+-- docs/
|   +-- README-en.md           # English guide
|   +-- README-zh.md           # Chinese guide
|   +-- README-ja.md           # Japanese guide
|   +-- architecture.md        # Architecture docs
|   +-- troubleshooting.md     # Common issues
+-- scripts/
|   +-- windows/               # Windows scripts
|   +-- linux/                 # Linux scripts
|   +-- macos/                 # macOS scripts
+-- configs/
|   +-- docker-compose.override.yml
|   +-- database.yml
|   +-- domain.yml
|   +-- security.yml
+-- docker/
    +-- Dockerfile.web.patch
    +-- Dockerfile.postgres.patch
```

## Download Links

| Resource | URL |
|----------|-----|
| Canvas LMS Official | https://github.com/instructure/canvas-lms |
| Canvas LMS (Gitee Mirror CN) | https://gitee.com/xiong-yuhui/canvas-Lms |
| Docker Desktop (Windows) | https://www.docker.com/products/docker-desktop/ |
| Docker Desktop (macOS) | https://www.docker.com/products/docker-desktop/ |
| Docker Engine (Linux) | https://docs.docker.com/engine/install/ |
| Git (Windows) | https://git-scm.com/download/win |
| Docker Mirror (China) | docker.1ms.run / docker.xuanyuan.me |

## License

MIT License for this toolkit. Canvas LMS is AGPL-3.0.