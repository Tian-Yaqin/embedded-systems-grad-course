# ── Stage 1: 构建 MkDocs ──────────────────────────────────────────────────────
FROM python:3.12-slim AS builder
WORKDIR /build
COPY svgbob /usr/local/bin/svgbob
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
RUN mkdocs build

# ── Stage 2: Nginx 提供静态文件 ───────────────────────────────────────────────
FROM nginx:alpine
COPY --from=builder /build/site /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
