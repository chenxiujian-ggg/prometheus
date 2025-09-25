#-------- 1. 构建参数 --------
ARG ARCH="amd64"
ARG OS="linux"

#-------- 2. 准备 bash --------
FROM alpine:3.19 AS builder
RUN apk add --no-cache bash && mkdir -p /tmp/bash && cp /bin/bash /tmp/bash/

#-------- 3. 正式镜像 --------
FROM quay.io/prometheus/busybox-${OS}-${ARCH}:latest
ARG ARCH
ARG OS

# 把 bash 带进来
COPY --from=builder /tmp/bash/bash /bin/bash

# 下载官方最新 release 的二进制（静态链接，busybox 里能跑）
ARG PROMETHEUS_VERSION=2.45.0   # 可改任意版本
ADD https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.${OS}-${ARCH}.tar.gz /tmp/prom.tgz
RUN tar -xzf /tmp/prom.tgz -C /tmp && \
    cp /tmp/prometheus*/prometheus /bin/prometheus && \
    cp /tmp/prometheus*/promtool   /bin/promtool   && \
    rm -rf /tmp/prom.tgz /tmp/prometheus*

# 默认配置
ADD https://raw.githubusercontent.com/prometheus/prometheus/main/documentation/examples/prometheus.yml /etc/prometheus/prometheus.yml

# 其余文件（仓库里一定有）
COPY LICENSE        /LICENSE
COPY NOTICE         /NOTICE

WORKDIR /prometheus
RUN chown -R nobody:nobody /etc/prometheus /prometheus && chmod g+w /prometheus

USER       nobody
EXPOSE     9090
VOLUME     [ "/prometheus" ]
ENTRYPOINT [ "/bin/prometheus" ]
CMD        [ "--config.file=/etc/prometheus/prometheus.yml", \
             "--storage.tsdb.path=/prometheus" ]
