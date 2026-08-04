# Base Image
FROM alpine:latest

# Create a non-root user
# Create a non-root user and group for Tor
RUN addgroup -S tor && \
    adduser -S -G tor tor && \
    adduser -D appuser

# Update and install required packages
RUN apk update && apk add --no-cache \
    python3 \
    py3-pip \
    bash \
    curl \
    wget \
    go \
    tor \
    openssl \
    sudo \
    libcap \
    dnsmasq \
    dnscrypt-proxy \
    dnscrypt-proxy-openrc \
    libunwind \
    libevent \
    nano \
    htop \
    stubby

# Set GOPATH and add Go to PATH
ENV GOPATH=/go
ENV PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

# Clone and build go-dispatch-proxy
RUN apk add --no-cache git && \
    git clone https://github.com/Alexey71/opera-proxy /tmp/opera-proxy && \
    cd /tmp/opera-proxy && \
    go build -o opera-vpn && \
    chmod +x opera-vpn && \
    mv opera-vpn /usr/bin/opera-vpn && \
    rm -rf /tmp/opera-proxy

# Copy hosts file
COPY hosts /etc/hosts2

# Copy start scripts
COPY start.sh /sbin/start.sh
RUN chmod +x /sbin/start.sh

# Copy dnscrypt-proxy settings
COPY dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml
RUN chown root:root /etc/dnscrypt-proxy/dnscrypt-proxy.toml && \
    chmod 755 /etc/dnscrypt-proxy/dnscrypt-proxy.toml

# Set working directory
WORKDIR /app

# Expose ports
EXPOSE 18080 18081

# Start Tor and the proxy
CMD ["/sbin/start.sh"]
