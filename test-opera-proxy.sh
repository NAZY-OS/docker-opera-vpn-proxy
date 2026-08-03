#!/bin/bash

# Configuration
TARGET_URL="https://api.ipify.org"  # URL that returns only the IP address
PROXY_URL="http://127.0.0.1:18080"  # HTTP proxy URL (adjust port if needed)

# Get IP without proxy
echo "Fetching IP without proxy..."
ip_without_proxy=$(curl -s "$TARGET_URL")

# Get IP with proxy
echo "Fetching IP with proxy..."
ip_with_proxy=$(curl -s -x "$PROXY_URL" "$TARGET_URL")

# Display results
echo "IP without proxy: $ip_without_proxy"
echo "IP with proxy:    $ip_with_proxy"

# Compare IPs
if [[ "$ip_without_proxy" != "$ip_with_proxy" ]]; then
    echo "Proxy is likely working! Different IPs detected."
    exit 0
else
    echo "Proxy might not be working. Same IP detected."
    exit 1
fi
