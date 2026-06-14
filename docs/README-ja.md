# Canvas LMS Docker デプロイガイド（日本語）

> Docker を使用して Canvas LMS をローカル環境にワンクリックでデプロイする完全ガイド。Windows / Linux / macOS 全プラットフォーム対応。

---

## 目次

1. [概要](#概要)
2. [システム要件](#システム要件)
3. [環境構築](#環境構築)
4. [クイックスタート](#クイックスタート)
5. [詳細セットアップ手順](#詳細セットアップ手順)
6. [設定](#設定)
7. [アーキテクチャ](#アーキテクチャ)
8. [使い方ガイド](#使い方ガイド)
9. [トラブルシューティング](#トラブルシューティング)
10. [ダウンロードリンク](#ダウンロードリンク)

---

## 概要

Canvas LMS は Instructure 社が開発したオープンソースの学習管理システム（LMS）です。世界中の数千の大学や教育機関で使用されています。本ツールキットは Docker コンテナ技術を活用し、デプロイプロセスを自動化することで、ローカル環境で Canvas LMS を簡単に実行できるようにします。

### デプロイされるコンポーネント

| コンポーネント | 説明 | 技術スタック |
|--------------|------|------------|
| Web サービス | Canvas メインアプリケーション | Ruby on Rails 6.x + Nginx + Passenger |
| バックグラウンドジョブ | 非同期タスク処理 | Delayed Jobs Worker |
| データベース | データストレージ | PostgreSQL 12 + PostGIS 2.5 |
| キャッシュ | キャッシュ＆メッセージキュー | Redis Alpine |

---

## システム要件

### 最小構成

| 項目 | 要件 |
|------|------|
| OS | Windows 10/11、Ubuntu 20.04 以上、macOS 12 以上 |
| CPU | 4 コア（推奨） |
| メモリ | 最低 8 GB、推奨 16 GB |
| ディスク | 30 GB 以上の空き容量 |
| ネットワーク | 初回セットアップ時にインターネット接続が必要 |

### Docker リソース割り当て

Docker Desktop の設定で以下のリソースを割り当ててください：

- **メモリ**：8 GB（最低）/ 12 GB（推奨）
- **CPU**：4 コア
- **ディスク**：60 GB
- **スワップ**：1 GB

---

## 環境構築

### Windows

#### 手順 1：Docker Desktop のインストール

1. ダウンロード先：https://www.docker.com/products/docker-desktop/
2. インストーラーを実行
3. インストール時に「Use WSL 2 instead of Hyper-V」にチェック
4. パソコンを再起動
5. Docker Desktop を開き、起動完了を待つ

確認：
```powershell
docker --version
docker compose version
```

#### 手順 2：Git のインストール

1. ダウンロード先：https://git-scm.com/download/win
2. デフォルト設定でインストール

確認：
```powershell
git --version
```

---

### Ubuntu / Debian Linux

#### 手順 1：Docker Engine のインストール

```bash
# 古いバージョンを削除
sudo apt-get remove docker docker-engine docker.io containerd runc

# 依存パッケージをインストール
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Docker GPG キーを追加
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# リポジトリを設定
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker をインストール
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 現在のユーザーを docker グループに追加（sudo 不要）
sudo usermod -aG docker $USER
newgrp docker
```

#### 手順 2：Git のインストール

```bash
sudo apt-get install -y git
git --version
```

---

### macOS

#### 手順 1：Docker Desktop のインストール

1. ダウンロード先：https://www.docker.com/products/docker-desktop/
2. チップに応じて選択：
   - Apple Silicon (M1/M2/M3/M4)：「Mac with Apple Chip」
   - Intel：「Mac with Intel Chip」
3. Applications フォルダにドラッグ
4. Docker Desktop を起動

確認：
```bash
docker --version
docker compose version
```

#### 手順 2：Git のインストール

```bash
xcode-select --install
```

---

## クイックスタート

### ワンクリックセットアップ

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

## 詳細セットアップ手順

### 手順 1：Canvas LMS リポジトリのクローン

```bash
# 公式リポジトリ
git clone https://github.com/instructure/canvas-lms.git

# Gitee ミラー（中国大陸ユーザー向け）
git clone https://gitee.com/xiong-yuhui/canvas-Lms.git canvas-lms
```

### 手順 2：パッチ設定の適用

```bash
cp configs/docker-compose.override.yml canvas-lms/
cp configs/database.yml canvas-lms/config/
cp configs/domain.yml canvas-lms/config/
cp configs/security.yml canvas-lms/config/
```

### 手順 3：Docker イメージのプル

```bash
# 通常プル（Docker Hub にアクセス可能な場合）
docker pull instructure/ruby-passenger:2.7
docker pull postgis/postgis:12-2.5
docker pull redis:alpine

# ミラー使用（アクセスできない場合）
docker pull docker.1ms.run/instructure/ruby-passenger:2.7
docker tag docker.1ms.run/instructure/ruby-passenger:2.7 instructure/ruby-passenger:2.7

docker pull docker.1ms.run/postgis/postgis:12-2.5
docker tag docker.1ms.run/postgis/postgis:12-2.5 postgis/postgis:12-2.5

docker pull docker.1ms.run/library/redis:alpine
docker tag docker.1ms.run/library/redis:alpine redis:alpine
```

### 手順 4：ビルド＆起動

```bash
cd canvas-lms
docker compose -f docker-compose.yml -f docker-compose.override.yml build
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d
```

### 手順 5：データベースの初期化

```bash
# データベースの準備完了を待つ
docker compose exec postgres pg_isready -U canvas

# データベースを作成
docker compose exec web bundle exec rake db:create

# 初期セットアップ（管理者アカウントの作成など）
docker compose exec web bundle exec rake db:initial_setup

# データベースマイグレーションを実行
docker compose exec web bundle exec rake db:migrate
```

### 手順 6：Canvas LMS にアクセス

ブラウザで以下を開く：**http://localhost:3000**

---

## 設定

### docker-compose.override.yml

```yaml
services:
  web:
    ports:
      - "3000:80"        # 左側がホストポート、変更可能
    environment:
      RAILS_ENV: development
    volumes:
      - .:/usr/src/app   # ソースコードをマウント

  postgres:
    ports:
      - "5432:5432"

  redis:
    ports:
      - "6379:6379"
```

### database.yml

```yaml
development:
  adapter: postgresql
  encoding: utf8
  database: canvas_development
  host: postgres          # Docker サービス名
  username: canvas
  password: sekret
  timeout: 5000
```

### domain.yml

```yaml
development:
  domain: localhost
```

---

## アーキテクチャ

### サービストップロジー

```
                    +-------------------+
                    |   ロードバランサ    |
                    |   (localhost)     |
                    +--------+----------+
                             |
                    +--------v----------+
                    |   Web コンテナ     |
                    | Nginx + Passenger  |
                    | Ruby on Rails 6.x  |
                    | ポート: 3000 -> 80 |
                    +---+----------+----+
                        |          |
              +---------v--+  +---v---------+
              | PostgreSQL  |  |    Redis     |
              | + PostGIS   |  |  (キャッシュ) |
              | ポート:5432 |  | ポート:6379  |
              +-------------+  +--------------+
                        |
              +---------v----------+
              |   Jobs コンテナ     |
              |  非同期タスク処理    |
              |  バックグラウンド   |
              +--------------------+
```

### 技術スタック

| レイヤー | 技術 | バージョン |
|---------|------|----------|
| Web フレームワーク | Ruby on Rails | 6.x |
| プログラミング言語 | Ruby | 2.7 |
| Web サーバー | Nginx + Phusion Passenger | - |
| データベース | PostgreSQL + PostGIS | 12 + 2.5 |
| キャッシュ | Redis | Alpine |
| フロントエンド | Node.js + Yarn + Webpack | 14 + 1.19.1 |
| パッケージ管理 | Bundler | 2.2.17 |
| コンテナ | Docker + Docker Compose | v2 |

---

## 使い方ガイド

### Canvas LMS の起動

```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d
```

### Canvas LMS の停止

```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml down
```

### ログの確認

```bash
# 全サービス
docker compose logs -f

# 特定のサービス
docker compose logs -f web
docker compose logs -f jobs
docker compose logs -f postgres
```

### Rails コンソール

```bash
docker compose exec web bundle exec rails console
```

### データベースマイグレーション

```bash
docker compose exec web bundle exec rake db:migrate
```

### 管理者ユーザーの作成

```bash
docker compose exec web bundle exec rails console
```
```ruby
# コンソール内で実行：
u = User.create!(name: "Admin", email: "admin@example.com", password: "password123")
u.pseudonyms.create!(unique_id: "admin@example.com", password: "password123", password_confirmation: "password123")
u.account_users.create!(account: Account.default, role: Role.default_account_role)
```

---

## トラブルシューティング

### ビルド失敗：GPG キーの有効期限切れ

**エラー：** `The repository ... is not signed`

**解決策：** パッチ済み Dockerfile が自動的に最新のキーをインポートします。

### ビルド失敗：Release ファイルがない

**エラー：** `does not have a Release file`

**解決策：** リポジトリ行に `[trusted=yes]` を追加し、apt-get update を `|| true` でラップ：
```dockerfile
echo "deb [trusted=yes] http://apt.postgresql.org/pub/repos/apt/ focal-pgdg main"
RUN ... && (apt-get update -qq || true) && ...
```

### Docker Hub にアクセスできない

**解決策：** ミラーレジストリを使用：
```bash
docker pull docker.1ms.run/instructure/ruby-passenger:2.7
docker tag docker.1ms.run/instructure/ruby-passenger:2.7 instructure/ruby-passenger:2.7
```

### ポートが使用中

**解決策：** `docker-compose.override.yml` のポートマッピングを変更：
```yaml
web:
  ports:
    - "8080:80"
```

### メモリ不足

**解決策：** Docker Desktop のメモリ割り当てを 12 GB 以上に増やす。

---

## ダウンロードリンク

| リソース | URL | 備考 |
|---------|-----|------|
| Canvas LMS 公式リポジトリ | https://github.com/instructure/canvas-lms | GitHub 公式 |
| Canvas LMS Gitee ミラー | https://gitee.com/xiong-yuhui/canvas-Lms | 中国大陸向け |
| Docker Desktop (Windows) | https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe | Windows インストーラ |
| Docker Desktop (macOS Apple Silicon) | https://desktop.docker.com/mac/main/arm64/Docker.dmg | M1/M2/M3 チップ |
| Docker Desktop (macOS Intel) | https://desktop.docker.com/mac/main/amd64/Docker.dmg | Intel チップ |
| Docker Engine (Linux) | https://docs.docker.com/engine/install/ | Linux インストールガイド |
| Git (Windows) | https://git-scm.com/download/win | Windows 用 Git |
| Docker ミラー (docker.1ms.run) | https://docker.1ms.run | 中国大陸アクセラレータ |
| Docker ミラー (docker.xuanyuan.me) | https://docker.xuanyuan.me | 中国大陸アクセラレータ |
| Docker ミラー (docker.m.daocloud.io) | https://docker.m.daocloud.io | 中国大陸アクセラレータ |

---

## ライセンス

本ツールキットは MIT ライセンスで提供されます。Canvas LMS 自体は AGPL-3.0 ライセンスです。