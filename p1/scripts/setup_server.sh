#!/bin/bash
set -e

echo "=== Detecting Network Configuration ==="

# Auto-detect the second network interface (supports eth1, enp0s8, etc.)
# Skip lo (loopback) and eth0/enp0s3 (NAT), use the second interface (private network)
INTERFACE=$(ip link show | grep -E "^[0-9]+:" | grep -v lo | awk -F: '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tail -1)
NODE_IP=""

if [ -z "$INTERFACE" ]; then
    echo "ERROR: Could not detect network interface"
    exit 1
fi

echo "Detected network interface: $INTERFACE"
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
echo "=== Installing K3s Server ==="

# Install k3s in SERVER mode with detected IP and interface
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=${NODE_IP} --advertise-address=${NODE_IP} --flannel-iface=${INTERFACE}" sh -

echo "=== K3s Server installed, waiting for token ==="

# Wait for node token file to be created
TOKEN_FILE="/var/lib/rancher/k3s/server/node-token"
while [ ! -f "$TOKEN_FILE" ]; do
	echo "Waiting for k3s server to generate node token..."
	sleep 2
done

echo "=== Token generated, starting token server ==="

# Start a simple HTTP server to share the token with worker nodes
TOKEN_DIR=$(mktemp -d)
cp "$TOKEN_FILE" "$TOKEN_DIR/node-token"
cd "$TOKEN_DIR"

# Start HTTP server in background on port 8080, bind to detected IP
nohup python3 -m http.server 8080 --bind "${NODE_IP}" > /var/log/token-server.log 2>&1 &
echo "Token server started on http://${NODE_IP}:8080/node-token"

# Keep the server running for 10 minutes then clean up
(sleep 600 && pkill -f "http.server 8080" 2>/dev/null) &

echo ""
echo "=== Generating external kubeconfig ==="

# Wait for K3s to be fully ready
echo "Waiting for K3s API server to be ready..."
for i in {1..30}; do
    if /usr/local/bin/kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get nodes &>/dev/null; then
        echo "✓ K3s API server is ready"
        break
    fi
    echo "Attempt $i/30: Waiting for K3s API..."
    sleep 2
done

# Make kubeconfig readable
sudo chmod 644 /etc/rancher/k3s/k3s.yaml

# Create an external kubeconfig using simple string extraction
# This avoids complex YAML parsing and is more reliable
EXTERNAL_CONFIG="/home/vagrant/k3s.yaml"

# Extract client cert and key from original kubeconfig
CLIENT_CERT=$(grep "client-certificate-data:" /etc/rancher/k3s/k3s.yaml | head -1 | awk '{print $2}')
CLIENT_KEY=$(grep "client-key-data:" /etc/rancher/k3s/k3s.yaml | head -1 | awk '{print $2}')

# Create the external kubeconfig file with insecure TLS verification
cat > "$EXTERNAL_CONFIG" << EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://${NODE_IP}:6443
  name: default
contexts:
- context:
    cluster: default
    user: default
  name: default
current-context: default
users:
- name: default
  user:
    client-certificate-data: ${CLIENT_CERT}
    client-key-data: ${CLIENT_KEY}
EOF

echo "✓ kubeconfig created at /home/vagrant/k3s.yaml"

# Copy kubeconfig to /vagrant (shared folder) if available for easy host access
if [ -d "/vagrant" ]; then
    cp "$EXTERNAL_CONFIG" /vagrant/k3s.yaml
    echo "✓ kubeconfig also copied to /vagrant/k3s.yaml for host access"
else
    echo "Note: /vagrant not available. Copy kubeconfig from host:"
    echo "  vagrant ssh macauchyS -c 'cat /home/vagrant/k3s.yaml' > k3s.yaml"
fi

echo ""
echo "=== K3s Server setup complete ==="
echo ""
echo "Access cluster from inside VM:"
echo "  kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get nodes"
echo ""
echo "Access cluster from host:"
echo "  export KUBECONFIG=\$PWD/k3s.yaml"
echo "  kubectl get nodes"
