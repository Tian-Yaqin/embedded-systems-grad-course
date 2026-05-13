# Coolify 项目部署配置指南

本文档说明如何在 Coolify 中正确部署机器人系统课程项目。

---

## ⚠️ 重要：必须使用 Docker Compose 方式

**本项目必须选择 `Docker Compose` 构建方式**，而不是 `Dockerfile` 方式。

### 为什么必须使用 Docker Compose？

本项目采用**微服务架构**，包含 **2 个独立容器**：

| 容器名 | 作用 | 技术栈 | 端口 |
|--------|------|--------|------|
| `web` | 前端静态站点服务 | MkDocs + Nginx | 80 |
| `api` | 后端 API 服务 | FastAPI + SQLite | 8000 |

这两个容器：
- **独立构建**：`web` 使用 `Dockerfile`，`api` 使用 `backend/Dockerfile`
- **相互依赖**：`web` 依赖 `api` 提供后端服务
- **共享网络**：通过 `coolify` 网络互联，允许 Caddy 代理访问
- **数据持久化**：`api` 使用 `exam_data` 卷存储 SQLite 数据库

**如果选择 Dockerfile 方式，只会构建单个容器，导致功能不完整！**

### Coolify 构建方式对比

Coolify 提供了 4 种构建方式，不同方式适用于不同的项目类型：

#### 1. Nixpacks（默认）⭐

**适用场景**：绝大多数无 Dockerfile 的项目，自动构建镜像

- 自动检测项目语言/框架（Node.js、Python、Go、Rust 等）
- 自动生成 Dockerfile，无需手动写配置
- 适合：前端框架（React/Vue）、后端服务（FastAPI/Express）、单容器应用

**优点**：
- ✅ 零配置、开箱即用
- ✅ Coolify 默认构建方式
- ✅ 自动优化构建流程

**缺点**：
- ❌ 无法处理多容器应用
- ❌ 自定义能力有限

#### 2. Static

**适用场景**：纯静态网站，无后端服务

- 直接部署 HTML/CSS/JS 静态文件
- 用内置的轻量 Web 服务器（Nginx）提供服务
- 适合：静态博客、文档网站、SPA 打包后的产物

**优点**：
- ✅ 构建速度极快
- ✅ 不需要任何构建步骤
- ✅ 直接部署静态文件

**缺点**：
- ❌ 不支持后端服务
- ❌ 不支持动态内容生成

#### 3. Dockerfile

**适用场景**：项目自带 Dockerfile，需要完全自定义构建流程

- 直接使用项目根目录下的 `Dockerfile` 构建镜像
- 适合：复杂构建流程（多阶段构建、自定义依赖）、需要精确控制镜像内容的场景

**优点**：
- ✅ 完全可控
- ✅ 和本地 `docker build` 流程一致
- ✅ 支持多阶段构建

**缺点**：
- ❌ **只构建单个容器**
- ❌ 不支持多容器编排
- ❌ 无法处理服务依赖

#### 4. Docker Compose（本项目使用）✅

**适用场景**：多容器应用，需要编排多个服务

- 直接使用项目根目录下的 `docker-compose.yml` 启动多容器服务
- 适合：前后端分离、带数据库/缓存的应用（比如 Nginx + FastAPI + Redis）

**优点**：
- ✅ 一键编排多个容器
- ✅ 支持服务依赖（`depends_on`）
- ✅ 支持网络、卷挂载等复杂配置
- ✅ 和本地开发环境一致

**缺点**：
- ❌ 需要手动编写 `docker-compose.yml`
- ❌ 配置相对复杂

---

**本项目为什么选择 Docker Compose？**

| 需求 | Nixpacks | Static | Dockerfile | Docker Compose |
|------|----------|--------|------------|----------------|
| 多容器支持 | ❌ | ❌ | ❌ | ✅ |
| 服务编排 | ❌ | ❌ | ❌ | ✅ |
| 前后端分离 | ❌ | ❌ | ❌ | ✅ |
| 数据持久化 | ⚠️ | ❌ | ⚠️ | ✅ |
| 网络隔离 | ❌ | ❌ | ❌ | ✅ |

**结论**：本项目有 2 个容器（web + api），必须使用 Docker Compose！

---

## 🏗️ 项目架构说明

### 容器架构

```
┌─────────────────────────────────────────────────┐
│              Coolify + Caddy                    │
│            (caddy: robotics.uwis.cn)             │
└────────────────┬────────────────────────────────┘
                 │
                 ├─────────────────┐
                 │                 │
          ┌──────▼──────┐   ┌─────▼──────┐
          │  web:80     │   │  api:8000  │
          │  (Nginx)    │   │ (FastAPI)  │
          │             │   │            │
          │  MkDocs     │   │  SQLite    │
          │  静态站点    │   │  考试系统   │
          └─────────────┘   └────────────┘
                                  │
                            ┌─────▼─────┐
                            │ exam_data │
                            │  (Volume) │
                            └───────────┘
```

### 数据流

1. **用户访问** `https://robotics.uwis.cn`
2. **Caddy 代理**将请求路由到 `web:80`
3. **Nginx** 提供 MkDocs 静态页面
4. **前端页面**通过 `/api/` 路径调用后端 API
5. **Nginx** 将 `/api/` 请求反向代理到 `api:8000`
6. **FastAPI** 处理请求并访问 SQLite 数据库
7. **数据持久化**在 `exam_data` 卷中

---

## 📋 Coolify 部署步骤

### 1. 创建新应用

1. 登录 Coolify: https://coolify.uwis.cn
2. 选择项目（如 `Robotics_Systems_Course`）
3. 点击 **New Resource** → **Public Repository**

### 2. 配置 Git 仓库

| 配置项 | 值 |
|--------|-----|
| Git Repository URL | `https://github.com/uwislab/robotics-systems-course.git` |
| Branch | `main` |
| **Build Pack** | **⚠️ 必须选择 `Docker Compose`** |

### 3. 配置域名

在 **Domains** 标签页：

| Service | Domain |
|---------|--------|
| `web` | `https://robotics.uwis.cn` |
| `api` | （不需要公开域名，内部访问） |

### 4. 配置环境变量

在 **Environment Variables** 标签页添加：

| Key | Value | 说明 |
|-----|-------|------|
| `TEACHER_PASSWORD` | `your_password` | 教师后台密码 |
| `JWT_SECRET` | `random_secret_string` | JWT 签名密钥（建议 32 字符以上随机字符串） |
| `DOCS_DIR` | `/app/docs` | Markdown 文档目录 |
| `DB_PATH` | `/app/data/exam.db` | SQLite 数据库路径 |

**生成随机密钥示例**：
```bash
openssl rand -hex 32
```

### 5. 配置持久化存储

Coolify 会自动创建 `exam_data` 卷，无需手动配置。

---

## ❤️ 健康检查配置（重要！）

### 为什么需要健康检查？

默认情况下，Coolify 会提示：

```
⚠️ No health check configured.
The resource may be functioning normally.
Traefik and Caddy will route traffic to this container even without a health check.
However, configuring a health check is recommended to ensure the resource is ready before receiving traffic.
```

**问题**：没有健康检查，Caddy 可能在容器启动完成前就开始路由流量，导致用户看到错误页面。

**解决方案**：为两个容器都添加健康检查配置。

### 添加健康检查

在 `docker-compose.yaml` 中为每个服务添加 `healthcheck` 配置：

#### Web 容器健康检查

```yaml
services:
  web:
    build:
      context: .
      network: host
    expose:
      - "80"
    restart: unless-stopped
    depends_on:
      - api
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:80/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    labels:
      caddy: "robotics.uwis.cn"
      caddy.reverse_proxy: "{{upstreams 80}}"
    networks:
      - coolify
```

#### API 容器健康检查

```yaml
  api:
    build:
      context: .
      dockerfile: backend/Dockerfile
      network: host
    expose:
      - "8000"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    volumes:
      - exam_data:/app/data
      - ./docs:/app/docs:rw
    environment:
      - TEACHER_PASSWORD=${TEACHER_PASSWORD:-admin123}
      - JWT_SECRET=${JWT_SECRET:-please-change-this-secret}
      - DB_PATH=/app/data/exam.db
      - DOCS_DIR=/app/docs
    networks:
      - coolify
```

### 健康检查参数说明

| 参数 | 值 | 说明 |
|------|-----|------|
| `test` | `wget` 命令 | 检查 HTTP 端点是否响应 |
| `interval` | `30s` | 每 30 秒检查一次 |
| `timeout` | `10s` | 单次检查超时时间 |
| `retries` | `3` | 连续失败 3 次才标记为 unhealthy |
| `start_period` | `40s` | 容器启动后等待 40 秒再开始检查（给服务启动留时间） |

### 健康检查工作流程

```
容器启动
    ↓
等待 40 秒（start_period）
    ↓
开始每 30 秒检查一次（interval）
    ↓
    ├─ 成功 → 标记为 healthy → Caddy 开始路由流量
    └─ 失败 → 重试 3 次 → 标记为 unhealthy → Caddy 停止路由流量
```

### 验证健康检查

部署完成后，在 Coolify 中应该看到：

```
✅ web: healthy
✅ api: healthy
```

如果看到 `unhealthy` 状态，检查：
1. 容器日志是否有错误
2. `start_period` 是否足够长（服务启动可能需要更多时间）
3. 健康检查端点是否正确（web 检查 `/`，api 检查 `/health`）

---

## 🚀 部署流程

### 首次部署

1. 完成上述所有配置
2. 点击 **Deploy** 按钮
3. 等待构建完成（约 5-10 分钟）
4. 访问 `https://robotics.uwis.cn` 验证

### 后续更新

**方式一：自动部署**

在应用设置中启用 **Auto Deploy**：
- 每次 `git push` 到 `main` 分支
- Coolify 自动拉取代码并重新部署

**方式二：手动部署**

在 Coolify 应用页面点击 **Deploy** 按钮。

### 查看日志

- **构建日志**：在部署页面查看 `Build` 标签
- **运行日志**：在应用页面查看 `Logs` 标签，可分别查看 `web` 和 `api` 容器日志

---

## 🔧 常见问题

### Q1: 为什么必须选择 Docker Compose？

**A**: 项目包含 2 个独立容器（web + api），只有 Docker Compose 能同时构建和运行多个容器。

### Q2: 如何验证两个容器都在运行？

**A**: 在 Coolify 应用页面可以看到两个容器的状态：
```
✅ web (80)
✅ api (8000)
```

### Q3: 健康检查失败怎么办？

**A**: 检查步骤：
1. 查看容器日志：`Logs` → 选择 `web` 或 `api`
2. 增加 `start_period`（如改为 60s）
3. 验证健康检查端点：
   - `web`: `http://localhost:80/` 应该返回 HTML 页面
   - `api`: `http://localhost:8000/health` 应该返回 JSON

### Q4: 数据会丢失吗？

**A**: 不会。SQLite 数据库存储在 `exam_data` 卷中，即使重新部署也会保留。

### Q5: 如何更新环境变量？

**A**: 
1. 在 Coolify 中修改环境变量
2. 点击 **Restart** 重启容器
3. 新的环境变量会自动注入

---

## 📚 参考资料

- [Coolify 官方文档](https://coolify.io/docs)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [健康检查配置说明](https://docs.docker.com/engine/reference/builder/#healthcheck)

---

## 📝 配置清单

部署前请确认：

- [ ] Git 仓库 URL 正确
- [ ] Branch 选择 `main`
- [ ] **Build Pack 选择 `Docker Compose`**（最重要！）
- [ ] 域名配置：`web` → `robotics.uwis.cn`
- [ ] 环境变量：`TEACHER_PASSWORD`, `JWT_SECRET`, `DOCS_DIR`, `DB_PATH`
- [ ] 健康检查已添加到 `docker-compose.yaml`
- [ ] 两个容器都显示 `healthy` 状态

---

**最后提醒**：如果部署后发现只有一个容器运行，说明选错了构建方式，请删除应用重新创建，确保选择 **Docker Compose**！
