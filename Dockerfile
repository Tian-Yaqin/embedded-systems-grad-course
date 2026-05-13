# ── Stage 1: 构建 MkDocs ──────────────────────────────────────────────────────
FROM python:3.12-alpine AS builder
WORKDIR /build
# 使用预编译的 svgbob_cli 以加速构建（避免每次编译 Rust 项目，节省约 5-10 分钟）
RUN apk add --no-cache libgcc  # svgbob_cli 运行时依赖
COPY bin/svgbob_cli /usr/local/bin/svgbob_cli
RUN chmod +x /usr/local/bin/svgbob_cli \
	&& ln -sf /usr/local/bin/svgbob_cli /usr/local/bin/svgbob
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
RUN mkdocs build

# ── Stage 2: Nginx 提供静态文件 ───────────────────────────────────────────────
FROM nginx:alpine
COPY --from=builder /build/site /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
