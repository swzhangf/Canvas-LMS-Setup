# Canvas LMS Troubleshooting Guide / 故障排除指南 / トラブルシューティングガイド

## Common Issues

---

### 1. Docker Build Fails: GPG Key Expired / GPG密钥过期 / GPGキー有効期限切れ

**Error:**
```
The repository 'https://oss-binaries.phusionpassenger.com/apt/passenger focal Release' is not signed.
```

**Solution / 解决方案 / 解決策:**
```dockerfile
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys D870AB033FB45BD1
```

---

### 2. apt-get Repository Missing Release File / 仓库缺少Release文件 / リポジトリにReleaseファイルがない

**Error:**
```
E: The repository 'http://apt.postgresql.org/pub/repos/apt focal-pgdg Release' does not have a Release file.
```

**Solution / 解决方案 / 解決策:**
```dockerfile
# Add [trusted=yes] to the repository line
echo "deb [trusted=yes] http://apt.postgresql.org/pub/repos/apt/ focal-pgdg main"
# Allow apt-get update to fail gracefully
RUN ... && (apt-get update -qq || true) && ...
```

---

### 3. Docker Hub Unreachable / Docker Hub无法访问 / Docker Hubにアクセスできない

**Error:**
```
Error response from daemon: Get "https://registry-1.docker.io/v2/": net/http: request canceled
```

**Solution / 解决方案 / 解決策:**

**Option A: Use Mirror / 使用镜像 / ミラー使用:**
```bash
# Windows PowerShell
docker pull docker.1ms.run/instructure/ruby-passenger:2.7
docker tag docker.1ms.run/instructure/ruby-passenger:2.7 instructure/ruby-passenger:2.7

# Linux/macOS
docker pull docker.1ms.run/instructure/ruby-passenger:2.7
docker tag docker.1ms.run/instructure/ruby-passenger:2.7 instructure/ruby-passenger:2.7
```

**Option B: Configure Docker Daemon Mirror / 配置Docker镜像加速 / Dockerデーモンミラー設定:**

Windows/macOS: Docker Desktop -> Settings -> Docker Engine:
```json
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.xuanyuan.me",
    "https://docker.m.daocloud.io"
  ]
}
```

Linux:
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
sudo systemctl restart docker
```

---

### 4. GitHub Unreachable (China) / GitHub无法访问（中国大陆） / GitHubにアクセスできない

**Solution / 解决方案 / 解決策:**
```bash
# Use Gitee mirror
git clone https://gitee.com/xiong-yuhai/canvas-Lms.git canvas-lms
```

---

### 5. Port Already in Use / 端口被占用 / ポートが使用中

**Error:**
```
Error starting userland proxy: listen tcp4 0.0.0.0:3000: bind: address already in use
```

**Solution / 解决方案 / 解決策:**

Edit `docker-compose.override.yml`:
```yaml
web:
  ports:
    - "8080:80"   # Change 3000 to 8080 (or any available port)
```

**Find what's using the port / 查找占用端口的进程 / ポート使用中のプロセス:**
```bash
# Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Linux/macOS
lsof -i :3000
kill -9 <PID>
```

---

### 6. Out of Memory / 内存不足 / メモリ不足

**Symptoms / 症状:**
- Container exits with code 137
- "Killed" in logs
- Very slow build

**Solution / 解决方案 / 解決策:**

**Windows/macOS:**
1. Open Docker Desktop
2. Settings -> Resources
3. Increase Memory to 12+ GB
4. Apply & Restart

**Linux:**
```bash
# Add swap space if needed
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

---

### 7. Debian Buster Repos Archived / Debian Buster仓库已归档 / Debian Busterリポジトリがアーカイブ

**Error:**
```
E: The repository 'http://deb.debian.org/debian buster Release' does not have a Release file.
```

**Solution / 解决方案 / 解決策:**
```dockerfile
RUN sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list
RUN sed -i 's|security.debian.org|archive.debian.org/debian-security|g' /etc/apt/sources.list
RUN sed -i '/buster-updates/d' /etc/apt/sources.list
RUN echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until
```

---

### 8. Database Connection Failed / 数据库连接失败 / データベース接続に失敗

**Solution / 解决方案 / 解決策:**

```bash
# Check postgres is running
docker compose ps postgres

# Check postgres logs
docker compose logs postgres

# Wait for postgres
docker compose exec -T postgres pg_isready -U canvas

# If needed, restart postgres
docker compose restart postgres
```

---

### 9. Permission Denied (Windows E: Drive) / 权限拒绝（Windows E盘） / 権限拒否

**Error:**
```
Permission denied when writing to E:\Canvas LMS
```

**Solution / 解决方案 / 解決策:**

```powershell
# Take ownership of the directory
takeown /f "E:\Canvas LMS" /r /d y
icacls "E:\Canvas LMS" /grant "${env:USERNAME}:(OI)(CI)F" /t
```

Or run PowerShell as Administrator.

---

### 10. Docker Compose Version Attribute Warning

**Warning:**
```
the attribute `version` is obsolete, please remove it
```

**Solution / 解决方案 / 解決策:**

Remove the `version: '2.3'` line from `docker-compose.yml` and `docker-compose.override.yml`. This is just a warning and does not affect functionality.

---

## Debug Commands / 调试命令 / デバッグコマンド

```bash
# Check all services status
docker compose ps

# View logs for all services
docker compose logs -f

# View logs for specific service
docker compose logs -f web
docker compose logs -f jobs
docker compose logs -f postgres

# Shell into web container
docker compose exec web bash

# Shell into postgres container
docker compose exec postgres psql -U canvas -d canvas_development

# Check disk space in containers
docker compose exec web df -h

# Check memory usage
docker stats

# Full rebuild (no cache)
docker compose -f docker-compose.yml -f docker-compose.override.yml build --no-cache

# Reset everything
docker compose -f docker-compose.yml -f docker-compose.override.yml down -v
docker compose -f docker-compose.yml -f docker-compose.override.yml build
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d
```