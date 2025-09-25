FROM alpine:latest as builder  
  
# 安装构建依赖  
RUN apk add --no-cache ca-certificates  
  
FROM alpine:latest  
  
# 安装bash和运行时依赖  
RUN apk add --no-cache bash curl wget ca-certificates  
  
# 创建prometheus用户  
RUN addgroup -g 65534 nobody && \  
    adduser -D -u 65534 -G nobody -s /bin/bash nobody  
  
# 复制prometheus二进制文件（需要先构建）  
COPY prometheus /bin/prometheus  
COPY promtool /bin/promtool  
COPY prometheus.yml /etc/prometheus/prometheus.yml  
  
# 设置工作目录和权限  
RUN mkdir -p /prometheus && \  
    chown -R nobody:nobody /etc/prometheus /prometheus  
  
USER nobody  
EXPOSE 9090  
VOLUME ["/prometheus"]  
WORKDIR /prometheus  
  
ENTRYPOINT ["/bin/prometheus"]  
CMD ["--config.file=/etc/prometheus/prometheus.yml", \  
     "--storage.tsdb.path=/prometheus", \  
     "--web.console.libraries=/etc/prometheus/console_libraries", \  
     "--web.console.templates=/etc/prometheus/consoles", \  
     "--web.enable-lifecycle"]
