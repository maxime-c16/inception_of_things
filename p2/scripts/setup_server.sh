#!/bin/bash
set -e

echo "=== Installing K3s Server (Single Node) ==="

# Install k3s in SERVER mode (idempotent)
if command -v k3s >/dev/null 2>&1; then
    echo "k3s already installed; skipping installation"
else
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.110 --advertise-address=192.168.56.110 --flannel-iface=eth1" sh -
fi

echo "=== K3s Server installed, waiting for readiness ==="

# Wait for K3s to be ready
kubectl_path="/usr/local/bin/kubectl"
max_retries=30
retry=0

while ! $kubectl_path get node &>/dev/null && [ $retry -lt $max_retries ]; do
    echo "Waiting for K3s API to be ready... ($retry/$max_retries)"
    sleep 5
    retry=$((retry + 1))
done

if [ $retry -ge $max_retries ]; then
    echo "ERROR: K3s failed to start within timeout"
    exit 1
fi

echo "=== K3s API ready, deploying applications ==="

# Make kubeconfig readable
chmod 644 /etc/rancher/k3s/k3s.yaml

# Create a temporary kubeconfig
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Wait for traefik to be ready
$kubectl_path wait --for=condition=ready pod -l app.kubernetes.io/name=traefik -n kube-system --timeout=300s 2>/dev/null || true

# Deploy P2 applications
echo "=== Deploying P2 applications from confs/ ==="
$kubectl_path apply -f /home/vagrant/confs/apps.yaml
$kubectl_path apply -f /home/vagrant/confs/ingress.yaml

echo "=== P2 K3s Server setup complete ==="
