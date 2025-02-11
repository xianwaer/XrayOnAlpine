#!/bin/bash

# Exit on any error
set -e

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Ensure script runs as root
if [[ $EUID -ne 0 ]]; then
    log "Error: This script must be run as root!"
    exit 1
fi

# Function to get public IP (IPv4 preferred, fallback to IPv6)
getIP() {
    local serverIP
    # Try multiple IP detection services for redundancy
    for api in "https://api64.ipify.org" "https://ifconfig.me" "https://icanhazip.com"; do
        serverIP=$(curl -s -4 --connect-timeout 5 "$api") && break
    done
    
    if [[ -z "$serverIP" ]]; then
        for api in "https://api64.ipify.org" "https://ifconfig.me" "https://icanhazip.com"; do
            serverIP=$(curl -s -6 --connect-timeout 5 "$api") && break
        done
    fi
    
    if [[ -z "$serverIP" ]]; then
        log "Error: Could not determine server IP address"
        exit 1
    fi
    echo "$serverIP"
}

# Install required packages
log "Installing required packages..."
apk add --no-cache bash curl wget openssl coreutils

# Generate a strong random password (32 characters)
hyPasswd=$(openssl rand -base64 24)

# Select a random port (avoid common ports)
getPort=$(shuf -i 10000-65000 -n 1)

# Get the latest Hysteria 2 version
log "Detecting latest Hysteria 2 version..."
HY2_VERSION=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | grep -oP '"tag_name": "\K(.*?)(?=")')
if [[ -z "$HY2_VERSION" ]]; then
    log "Error: Could not detect latest version"
    exit 1
fi

HY2_VERSION_ESCAPED=$(echo "$HY2_VERSION" | sed 's/\//%2F/g')

# Determine system architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)  HY2_ARCH="amd64" ;;
    aarch64) HY2_ARCH="arm64" ;;
    armv7l)  HY2_ARCH="armv7" ;;
    *)
        log "Error: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Download and install Hysteria 2
log "Downloading Hysteria 2 version $HY2_VERSION..."
DOWNLOAD_URL="https://github.com/apernet/hysteria/releases/download/$HY2_VERSION_ESCAPED/hysteria-linux-$HY2_ARCH"
if ! wget -qO /usr/local/bin/hysteria "$DOWNLOAD_URL"; then
    log "Error: Failed to download Hysteria 2"
    exit 1
fi
chmod +x /usr/local/bin/hysteria

# Create configuration directory
mkdir -p /etc/hysteria/

# Generate self-signed TLS certificate
log "Generating TLS certificate..."
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
    -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt \
    -subj "/CN=bing.com" -days 36500

# Secure certificate files
chown root:root /etc/hysteria/server.key /etc/hysteria/server.crt
chmod 600 /etc/hysteria/server.key /etc/hysteria/server.crt

# Create server configuration
log "Creating server configuration..."
cat >/etc/hysteria/config.yaml <<EOF
listen: :$getPort
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key
auth:
  type: password
  password: $hyPasswd
masquerade:
  type: proxy
  proxy:
    url: https://bing.com
    rewriteHost: true
quic:
  initStreamReceiveWindow: 26843545 
  maxStreamReceiveWindow: 26843545 
  initConnReceiveWindow: 67108864 
  maxConnReceiveWindow: 67108864 
bandwidth:
  up: 1 gbps
  down: 1 gbps
EOF

# Create OpenRC service
log "Creating OpenRC service..."
cat <<EOF > /etc/init.d/hysteria
#!/sbin/openrc-run

name="hysteria"
description="Hysteria 2 Proxy Service"
command="/usr/local/bin/hysteria"
command_args="server -c /etc/hysteria/config.yaml"
command_background="yes"
pidfile="/run/\${RC_SVCNAME}.pid"
output_log="/var/log/hysteria.log"
error_log="/var/log/hysteria.err"

depend() {
    need net
    after firewall
}

start_pre() {
    if [ ! -f /etc/hysteria/config.yaml ]; then
        eerror "Configuration file not found: /etc/hysteria/config.yaml"
        return 1
    fi
    checkpath -f -m 0644 -o root:root "\$output_log" "\$error_log"
}
EOF

chmod +x /etc/init.d/hysteria
rc-update add hysteria default

# Get server IP
serverIP=$(getIP)

# Configure firewall (if installed)
if command -v ufw >/dev/null 2>&1; then
    log "Configuring UFW firewall..."
    ufw allow "$getPort"/udp
fi

# Start the service
log "Starting Hysteria service..."
rc-service hysteria restart

# Display connection information
echo "==============================================="
echo "Hysteria 2 Installation Complete!"
echo "Connection String:"
echo "hysteria2://${hyPasswd}@${serverIP}:${getPort}/?insecure=1&sni=bing.com#Hysteria2-$(date +%Y%m%d)"
echo "==============================================="
echo "Config file location: /etc/hysteria/config.yaml"
echo "Log files: /var/log/hysteria.log and /var/log/hysteria.err"
