#!/bin/bash
set -e

echo "=== Installing K3s Server ==="

# Install k3s in SERVER mode with private network configuration
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.110 --advertise-address=192.168.56.110 --flannel-iface=eth1" sh -

echo "=== K3s Server installed, waiting for token ==="

# Wait for node token file to be created
TOKEN_FILE="/var/lib/rancher/k3s/server/node-token"
while [ ! -f "$TOKEN_FILE" ]; do
	echo "Waiting for k3s server to generate node token..."
	sleep 2
done

echo "=== Token generated, starting token server ==="

# Start a simple HTTP server to share the token with worker nodes
# Using Python's HTTP server to serve the token file
TOKEN_DIR=$(mktemp -d)
cp "$TOKEN_FILE" "$TOKEN_DIR/node-token"
cd "$TOKEN_DIR"

# Start HTTP server in background on port 8080, bind to private network IP
nohup python3 -m http.server 8080 --bind 192.168.56.110 > /var/log/token-server.log 2>&1 &
echo "Token server started on http://192.168.56.110:8080/node-token"

# Keep the server running for 10 minutes then clean up
(sleep 600 && pkill -f "http.server 8080" 2>/dev/null) &

echo "=== K3s Server setup complete ==="
