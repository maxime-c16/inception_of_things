#!/bin/bash
set -e

echo "=== Setting up K3s Worker ==="

# Wait for token from server
TOKEN_FILE="/vagrant/node-token"
while [ ! -f "$TOKEN_FILE" ]; do
	echo "Waiting for k3s server to generate node token..."
	sleep 2
done

TOKEN=$(cat "$TOKEN_FILE")
echo "=== Token received, installing K3s Agent ==="

# Install k3s in AGENT mode, pointing to server's IP
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=$TOKEN sh -

echo "=== K3s Worker setup complete ==="
