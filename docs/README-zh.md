# Canvas LMS Docker 部署指南（简体中文）

> 使用 Docker 在本地一键部署 Canvas LMS 的完整教程，支持 Windows / Linux / macOS 全平台。

---

## 目录

1. [概述](#概述)
2. [系统要求](#系统要求)
3. [环境安装](#环境安装)
4. [快速开始](#快速开始)
5. [详细部署步骤](#详细部署步骤)
6. [配置说明](#配置说明)
7. [系统架构](#系统架构)
8. [使用指南](#使用指南)
9. [常见问题](#常见问题)
10. [下载链接汇总](#下载链接汇总)

---

## 概述

Canvas LMS 是由 Instructure 公司开发的开源学习管理系统（LMS），被全球数千所高校和机构使用。本工具包通过 Docker 容器化技术，将整个部署流程自动化，让您可以在本地轻松运行 Canvas LMS。

### 部署组件

| 组件 | 说明 | 技术栈 |
|------|------|--------|
| Web 服务 | Canvas 主应用 | Ruby on Rails 6.x + Nginx + Passenger |
| 后台任务 | 异步任务处理 | Delayed Jobs Worker |
| 数据库 | 数据存储 | PostgreSQL 12 + PostGIS 2.5 |
| 缓存 | 缓存与消息队列 | Redis Alpine |

---

## 系统要求

### 最低配置

| 项目 | 要求 |
|------|------|
| 操作系统 | Windows 10/11、Ubuntu 20.04+、macOS 12+ |
| CPU | 4 核（推荐） |
| 内存 | 最低 8 GB，推荐 16 GB |
| 磁盘 | 至少 30 GB 可用空间 |
| 网络 | 需要互联网连接（首次安装） |

### Docker 资源配置

在 Docker Desktop 设置中分配以下资源：

- **内存**：8 GB（最低）/ 12 GB（推荐）
- **CPU**：4 核
- **磁盘**：60 GB
- **Swap**：1 GB

---

## 环境安装

### Windows 系统

#### 第一步：安装 Docker Desktop

1. 下载地址：https://www.docker.com/products/docker-desktop/
2. 运行安装程序
3. 安装时勾选 "Use WSL 2 instead of Hyper-V"
4. 重启电脑
5. 打开 Docker Desktop，等待启动完成

验证安装：
```powershell
docker --version
docker compose version
```

#### 第二步：安装 Git

1. 下载地址：https://git-scm.com/download/win
2. 使用默认设置安装

验证安装：
```powershell
git --version
```

#### 第三步：（中国大陆用户）配置 Docker 镜像加速

如果无法直接访问 Docker Hub，需要配置镜像加速器：

1. 打开 Docker Desktop -> Settings -> Docker Engine
2. 添加以下内容：
```json
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.xuanyuan.me",
    "https://docker.m.daocloud.io"
  ]
}
```
3. 点击 "Apply & Restart"

#### 第四步：（中国大陆用户）手动拉取镜像

如果镜像加速器仍然无法使用，可以手动通过镜像拉取：

```powershell
# 拉取 Ruby 基础镜像
docker pull docker.1ms.run/instructure/ruby-passenger:2.7
docker tag docker.1ms.run/instructure/ruby-passenger:2.7 instructure/ruby-passenger:2.7

# 拉取 PostgreSQL + PostGIS 镜像
docker pull docker.1ms.run/postgis/postgis:12-2.5
docker tag docker.1ms.run/postgis/postgis:12-2.5 postgis/postgis:12-2.5

# 拉取 Redis 镜像
docker pull docker.1ms.run/library/redis:alpine
docker tag docker.1ms.run/library/redis:alpine redis:alpine
```

---

### Ubuntu / Debian Linux 系统

#### 第一步：安装 Docker Engine

```bash
# 卸载旧版本
sudo apt-get remove docker docker-engine docker.io containerd runc

# 安装依赖
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# 添加 Docker GPG 密钥
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 设置仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装 Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 将当前用户加入 docker 组（免 sudo）
sudo usermod -aG docker $USER
newgrp docker
```

验证：
```bash
docker --version
docker compose version
```

#### 第二步：安装 Git

```bash
sudo apt-get install -y git
git --version
```

#### 第三步：（中国大陆用户）配置 Docker 镜像加速

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

### macOS 系统

#### 第一步：安装 Docker Desktop

1. 下载地址：https://www.docker.com/products/docker-desktop/
2. 根据芯片选择版本：
   - Apple Silicon (M1/M2/M3/M4)：选择 "Mac with Apple Chip"
   - Intel：选择 "Mac with Intel Chip"
3. 拖拽到 Applications 文件夹
4. 启动 Docker Desktop

验证：
```bash
docker --version
docker compose version
```

#### 第二步：安装 Git

```bash
# 通过 Xcode 命令行工具安装
xcode-select --install
```

---

## 快速开始

### 一键部署

**Windows（PowerShell）：**
```powershell
git clone https://github.com/your-org/canvas-lms-setup.git
cd canvas-lms-setup
.\setup.ps1 -InstallPath "E:\Canvas LMS"
```

**Linux / macOS（Bash）：**
```bash
git clone https://github.com/your-org/canvas-lms-setup.git
cd canvas-lms-setup
chmod +x setup.sh
./setup.sh --install-path /opt/canvas-lms
```

---

## 详细部署步骤

### 步骤一：克隆 Canvas LMS 仓库

```bash
# 官方仓库（中国大陆可能较慢）
git clone https://github.com/instructure/canvas-lms.git

# 中国大陆用户推荐使用 Gitee 镜像
git clone https://gitee.com/xiong-yuhui/canvas-Lms.git canvas-lms
```

### 步骤二：应用补丁配置

将我们的修复配置文件复制到 Canvas LMS 目录：

```bash
# Linux / macOS
cp configs/docker-compose.override.yml canvas-lms/
cp configs/database.yml canvas-lms/config/
cp configs/domain.yml canvas-lms/config/
cp configs/security.yml canvas-lms/config/
```

```powershell
# Windows PowerShell
Copy-Item configs\docker-compose.override.yml canvas-lms\
Copy-Item configs\database.yml canvas-lms\config\
Copy-Item configs\domain.yml canvas-lms\config\
Copy-Item configs\security.yml canvas-lms\config\
```

### 步骤三：拉取 Docker 镜像

```bash
# 直接拉取（网络正常时）
docker pull instructure/ruby-passenger:2.7
docker pull postgis/postgis:12-2.5
docker pull redis:alpine

# 中国大陆镜像拉取
docker pull docker.1ms.run/instructure/ruby-passenger:2.7
docker tag docker.1ms.run/instructure/ruby-passenger:2.7 instructure/ruby-passenger:2.7

docker pull docker.1ms.run/postgis/postgis:12-2.5
docker tag docker.1ms.run/postgis/postgis:12-2.5 postgis/postgis:12-2.5

docker pull docker.1ms.run/library/redis:alpine
docker tag docker.1ms.run/library/redis:alpine redis:alpine
```

### 步骤四：构建并启动

```bash
cd canvas-lms
docker compose -f docker-compose.yml -f docker-compose.override.yml build
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d
```

### 步骤五：初始化数据库

```bash
# 等待数据库就绪
docker compose exec postgres pg_isready -U canvas

# 创建数据库
docker compose exec web bundle exec rake db:create

# 初始设置（创建管理员账户等）
docker compose exec web bundle exec rake db:initial_setup

# 运行数据库迁移
docker compose exec web bundle exec rake db:migrate
```

### 步骤六：访问 Canvas LMS

打开浏览器访问：**http://localhost:3000**

---

## 配置说明

### docker-compose.override.yml 核心配置

```yaml
services:
  web:
    ports:
      - "3000:80"        # 左侧为宿主机端口，可修改
    environment:
      RAILS_ENV: development
    volumes:
      - .:/usr/src/app   # 挂载源码用于开发

  postgres:
    ports:
      - "5432:5432"      # 暴露 PostgreSQL 端口

  redis:
    ports:
      - "6379:6379"      # 暴露 Redis 端口
```

### database.yml 数据库配置

```yaml
development:
  adapter: postgresql
  encoding: utf8
  database: canvas_development
  host: postgres          # Docker 服务名
  username: canvas
  password: sekret
  timeout: 5000
```

### domain.yml 域名配置

```yaml
development:
  domain: localhost       # 如需自定义域名请修改此处
```

---

## 系统架构

### 服务拓扑图

```
                    +-------------------+
                    |     负载均衡       |
                    |   (localhost)     |
                    +--------+----------+
                             |
                    +--------v----------+
                    |   Web 容器         |
                    | Nginx + Passenger  |
                    | Ruby on Rails 6.x  |
                    | 端口: 3000 -> 80   |
                    +---+----------+----+
                        |          |
              +---------v--+  +---v---------+
              | PostgreSQL  |  |    Redis     |
              | + PostGIS   |  |   (缓存)     |
              | 端口: 5432  |  | 端口: 6379   |
              +-------------+  +--------------+
                        |
              +---------v----------+
              |   Jobs 容器        |
              |  异步任务处理       |
              |  后台 Worker       |
              +--------------------+
```

### 技术栈

| 层级 | 技术 | 版本 |
|------|------|------|
| Web 框架 | Ruby on Rails | 6.x |
| 编程语言 | Ruby | 2.7 |
| Web 服务器 | Nginx + Phusion Passenger | - |
| 数据库 | PostgreSQL + PostGIS | 12 + 2.5 |
| 缓存 | Redis | Alpine |
| 前端 | Node.js + Yarn + Webpack | 14 + 1.19.1 |
| 包管理 | Bundler | 2.2.17 |
| 容器 | Docker + Docker Compose | v2 |

---

## 使用指南

### 启动 Canvas LMS

```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d
```

### 停止 Canvas LMS

```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml down
```

### 查看日志

```bash
# 所有服务
docker compose logs -f

# 指定服务
docker compose logs -f web
docker compose logs -f jobs
docker compose logs -f postgres
```

### 进入 Rails 控制台

```bash
docker compose exec web bundle exec rails console
```

### 运行数据库迁移

```bash
docker compose exec web bundle exec rake db:migrate
```

### 创建管理员用户

```bash
docker compose exec web bundle exec rails console
```
```ruby
# 在控制台中执行：
u = User.create!(name: "Admin", email: "admin@example.com", password: "password123")
u.pseudonyms.create!(unique_id: "admin@example.com", password: "password123", password_confirmation: "password123")
u.account_users.create!(account: Account.default, role: Role.default_account_role)
```

---

## 常见问题

### 构建失败：GPG 密钥过期

**错误信息：** `The repository ... is not signed`

**解决方案：** 我们的补丁 Dockerfile 已处理此问题，会自动导入最新密钥。

### 构建失败：仓库没有 Release 文件

**错误信息：** `does not have a Release file`

**解决方案：** 在仓库行添加 `[trusted=yes]` 并用 `|| true` 包裹 apt-get update：
```dockerfile
echo "deb [trusted=yes] http://apt.postgresql.org/pub/repos/apt/ focal-pgdg main"
RUN ... && (apt-get update -qq || true) && ...
```

### Docker Hub 无法访问（中国大陆）

**解决方案：** 使用镜像注册表：
```bash
docker pull docker.1ms.run/instructure/ruby-passenger:2.7
docker tag docker.1ms.run/instructure/ruby-passenger:2.7 instructure/ruby-passenger:2.7
```

### 端口被占用

**解决方案：** 修改 `docker-compose.override.yml` 中的端口映射：
```yaml
web:
  ports:
    - "8080:80"  # 使用 8080 端口
```

### 内存不足

**解决方案：** 在 Docker Desktop 中将内存分配增加到 12 GB 以上。

### 数据库连接失败

**解决方案：** 确认 postgres 容器运行正常：
```bash
docker compose ps
docker compose logs postgres
```

### Debian Buster 仓库已归档（PostGIS 镜像）

**解决方案：** PostGIS 12-2.5 基于 Debian Buster，需要切换到归档仓库：
```dockerfile
RUN sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list
RUN sed -i '/buster-updates/d' /etc/apt/sources.list
RUN echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until
```

---

## 下载链接汇总

| 资源 | 下载链接 | 说明 |
|------|----------|------|
| Canvas LMS 官方仓库 | https://github.com/instructure/canvas-lms | GitHub 官方 |
| Canvas LMS Gitee 镜像 | https://gitee.com/xiong-yuhui/canvas-Lms | 中国大陆推荐 |
| Docker Desktop (Windows) | https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe | Windows 安装包 |
| Docker Desktop (macOS Apple Silicon) | https://desktop.docker.com/mac/main/arm64/Docker.dmg | M1/M2/M3 芯片 |
| Docker Desktop (macOS Intel) | https://desktop.docker.com/mac/main/amd64/Docker.dmg | Intel 芯片 |
| Docker Engine (Linux) | https://docs.docker.com/engine/install/ | Linux 安装文档 |
| Git (Windows) | https://git-scm.com/download/win | Windows Git |
| Git (macOS) | https://git-scm.com/download/mac | macOS Git |
| Docker 镜像加速 (docker.1ms.run) | https://docker.1ms.run | 中国大陆加速 |
| Docker 镜像加速 (docker.xuanyuan.me) | https://docker.xuanyuan.me | 中国大陆加速 |
| Docker 镜像加速 (docker.m.daocloud.io) | https://docker.m.daocloud.io | 中国大陆加速 |

---

## 许可协议

本工具包使用 MIT 许可协议。Canvas LMS 本身使用 AGPL-3.0 许可协议。