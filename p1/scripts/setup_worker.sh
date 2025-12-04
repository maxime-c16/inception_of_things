#!/bin/bash
set -e

echo "=== Setting up K3s Worker ==="

# Fetch token from server via HTTP (server exposes it temporarily)
SERVER_IP="192.168.56.110"
TOKEN=""
MAX_RETRIES=60

echo "Waiting for K3s server token..."
for i in $(seq 1 $MAX_RETRIES); do
    TOKEN=$(curl -sf "http://${SERVER_IP}:8080/node-token" 2>/dev/null || true)
    if [ -n "$TOKEN" ]; then
        echo "Token received!"
        break
    fi
    echo "Attempt $i/$MAX_RETRIES - waiting for server..."
    sleep 5
done

if [ -z "$TOKEN" ]; then
    echo "ERROR: Failed to get token from server"
    exit 1
fi

echo "=== Token received, installing K3s Agent ==="

# Install k3s in AGENT mode with private network configuration
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=$TOKEN INSTALL_K3S_EXEC="--node-ip=192.168.56.111 --flannel-iface=eth1" sh -

echo "=== K3s Worker setup complete ==="
