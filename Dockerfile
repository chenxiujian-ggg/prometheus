#-------- 1. 构建参数（保持与原文件一致） --------
ARG ARCH="amd64"
ARG OS="linux"

#-------- 2. 解压/安装阶段（带包管理器） --------
FROM alpine:3.19 AS builder
# 安装 bash 和依赖（~6 MB），再把二进制拷贝到临时目录
RUN apk add --no-cache bash && \
    mkdir -p /tmp/bash && \
    cp /bin/bash /tmp/bash/

#-------- 3. 最终运行阶段（官方 busybox 基础） --------
FROM quay.io/prometheus/busybox-${OS}-${ARCH}:latest

# 重新声明 ARG，供后续变量替换
ARG ARCH
ARG OS

# 把 bash 复制进来（busybox 没有 apk/yum，只能手动拷）
COPY --from=builder /tmp/bash/bash /bin/bash

#-------- 4. 以下与你原 Dockerfile 完全一致 --------
LABEL maintainer="The Prometheus Authors <prometheus-developers@googlegroups.com>"
LABEL org.opencontainers.image.source="https://github.com/prometheus/prometheus"

COPY .build/${OS}-${ARCH}/prometheus        /bin/prometheus
COPY .build/${OS}-${ARCH}/promtool          /bin/promtool
COPY documentation/examples/prometheus.yml  /etc/prometheus/prometheus.yml
COPY LICENSE                                /LICENSE
COPY NOTICE                                 /NOTICE
# COPY npm_licenses.tar.bz2                   /npm_licenses.tar.bz2

WORKDIR /prometheus
RUN chown -R nobody:nobody /etc/prometheus /prometheus && chmod g+w /prometheus

USER       nobody
EXPOSE     9090
VOLUME     [ "/prometheus" ]
ENTRYPOINT [ "/bin/prometheus" ]
CMD        [ "--config.file=/etc/prometheus/prometheus.yml", \
             "--storage.tsdb.path=/prometheus" ]
