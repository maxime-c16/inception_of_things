#!/bin/bash
set -e

echo "=== Installing K3s Server ==="

# Install k3s in SERVER mode
curl -sfL https://get.k3s.io | sh -

echo "=== K3s Server installed, waiting for token ==="

# Wait for node token file to be created
TOKEN_FILE="/var/lib/rancher/k3s/server/node-token"
while [ ! -f "$TOKEN_FILE" ]; do
	echo "Waiting for k3s server to generate node token..."
	sleep 2
done

echo "=== Token generated, copying to shared folder ==="

# Copy the node token to shared /vagrant directory
cp "$TOKEN_FILE" /vagrant/node-token
chmod 644 /vagrant/node-token

# Copy kubeconfig to shared /vagrant directory for host access
cp /etc/rancher/k3s/k3s.yaml /vagrant/k3s.yaml
chmod 644 /vagrant/k3s.yaml

echo "=== K3s Server setup complete ==="
