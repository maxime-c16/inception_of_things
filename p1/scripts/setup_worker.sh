#!/bin/bash
set -e

echo "=== Detecting Network Configuration ==="

# Auto-detect the second network interface
# Try common names first: eth1, enp0s8, enp0s9 (in order)
INTERFACE=""
for iface in eth1 enp0s8 enp0s9 enp0s10; do
    if ip link show "$iface" &>/dev/null; then
        INTERFACE="$iface"
        echo "Detected network interface: $INTERFACE"
        break
    fi
done

if [ -z "$INTERFACE" ]; then
    echo "ERROR: Could not detect network interface (tried: eth1, enp0s8, enp0s9, enp0s10)"
    exit 1
fi

NODE_IP=""

echo "Waiting for $INTERFACE to be assigned an IP address..."
for i in {1..30}; do
    NODE_IP=$(ip addr show "$INTERFACE" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    if [ -n "$NODE_IP" ]; then
        echo "✓ Interface $INTERFACE configured with IP: $NODE_IP"
        break
    fi
    echo "Attempt $i/30: Waiting for IP assignment..."
    sleep 1
done

if [ -z "$NODE_IP" ]; then
    echo "ERROR: Could not detect IP on $INTERFACE"
    exit 1
fi

echo ""
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

# Install k3s in AGENT mode with detected IP and interface
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=$TOKEN INSTALL_K3S_EXEC="--node-ip=${NODE_IP} --flannel-iface=${INTERFACE}" sh -

echo "=== K3s Worker setup complete ==="
