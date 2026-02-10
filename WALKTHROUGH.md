# Inception of Things - Complete Walkthrough Guide

This guide provides step-by-step commands to set up and verify each part of the project.

---

## Part 1: Two-Node K3s Cluster with Vagrant

### Overview
- **Goal:** Deploy a 2-node Kubernetes cluster (server + worker) using Vagrant and K3s
- **VMs:** macauchyS (server, 192.168.56.110) and macauchySW (worker, 192.168.56.111)
- **Duration:** ~10-15 minutes for full provisioning

### Step-by-Step Setup

```bash
# Navigate to Part 1
cd p1

# Boot both VMs (this will take several minutes)
vagrant up

# Wait for provisioning to complete (watch for "Done" messages)
# If you see SSH connection errors, this is normal - K3s is still installing

# Once vagrant up completes, verify VMs are running
vagrant status

# SSH into the server VM
vagrant ssh macauchyS

# Inside the server VM, verify cluster status
kubectl get nodes
# Expected output:
#   NAME        STATUS   ROLES                  AGE
#   macauchyS   Ready    control-plane,master   Xm
#   macauchySW  Ready    <none>                 Ym

# View all system pods (should show Traefik, CoreDNS, etc.)
kubectl get pods -A

# Verify kubeconfig exists
cat ~/.kube/config

# Exit SSH
exit

# Back on host machine, copy kubeconfig for external kubectl access
vagrant ssh macauchyS -c "sudo cat /etc/rancher/k3s/k3s.yaml" > k3s.yaml

# Test kubectl from host (optional)
kubectl --kubeconfig=k3s.yaml get nodes
```

### Verification Checklist

- [ ] Both VMs are running: `vagrant status` shows "running"
- [ ] Both nodes are Ready: `kubectl get nodes` shows 2 nodes
- [ ] System pods are running: `kubectl get pods -A` shows 5+ pods
- [ ] Can SSH passwordless: `vagrant ssh macauchyS` works without prompts

### Common Issues

**Issue:** VMs fail to provision
- **Solution:** Check VirtualBox resources (CPU, RAM). Ensure host has 8GB RAM available.

**Issue:** K3s agent fails to join
- **Solution:** K3s is still initializing. Wait 2-3 more minutes and check logs: `vagrant ssh macauchySW -c "tail -20 /var/log/k3s-agent.log"`

**Issue:** kubectl command not found
- **Solution:** Ensure you're inside the Vagrant VM with `vagrant ssh macauchyS`

---

## Part 2: Three Applications with Traefik Ingress

### Overview
- **Goal:** Deploy a single-node K3s cluster with 3 web apps and Traefik ingress routing
- **VM:** macauchyS (192.168.56.110)
- **Ingress Routes:** app1.com → app-one, app2.com → app-two (3 replicas), / → app-three
- **Duration:** ~5 minutes

### Step-by-Step Setup

```bash
# Navigate to Part 2
cd p2

# Boot the VM
vagrant up

# Wait for K3s provisioning (~2-3 minutes)
# You can monitor with:
vagrant ssh macauchyS -c "sudo systemctl status k3s"

# Once provisioning completes, SSH into the VM
vagrant ssh macauchyS

# Inside VM: Verify K3s is running
kubectl get nodes
# Expected: 1 node (macauchyS) with Ready status

# Deploy the three applications
kubectl apply -f /vagrant/confs/apps.yaml

# Verify deployments created
kubectl get deployments
# Expected output:
#   NAME        READY   UP-TO-DATE   AVAILABLE   AGE
#   app-one     1/1     1            1           Xs
#   app-two     3/3     3            3           Xs
#   app-three   1/1     1            1           Xs

# Verify services created
kubectl get services
# Expected: app-one-svc, app-two-svc, app-three-svc (all ClusterIP type)

# Deploy Traefik ingress routing
kubectl apply -f /vagrant/confs/ingress.yaml

# Verify ingress is created
kubectl get ingress
# Expected: ingress-routing with 3 rules (app1.com, app2.com, default)

# Wait for Traefik to load ingress (usually ~10-15 seconds)
sleep 15

# Test ingress routing from inside the VM

# Test app1.com route (app-one)
curl -H 'Host: app1.com' http://192.168.56.110/
# Expected: "Hello from App One"

# Test app2.com route (app-two, one of 3 replicas)
curl -H 'Host: app2.com' http://192.168.56.110/
# Expected: "Hello from App Two"

# Test default route (app-three)
curl http://192.168.56.110/
# Expected: "Hello from App Three"

# Optional: Test app-two multiple times to see load balancing across replicas
for i in {1..5}; do
  echo "Request $i:"
  curl -H 'Host: app2.com' http://192.168.56.110/
done

# Exit VM
exit

# From host machine, test ingress (if network routing allows)
curl -H 'Host: app1.com' http://192.168.56.110/
# May work depending on network configuration
```

### Verification Checklist

- [ ] VM is running: `vagrant status` shows "running"
- [ ] K3s is ready: `kubectl get nodes` shows 1 node as Ready
- [ ] 3 deployments running: `kubectl get deployments` shows all as Ready
- [ ] 3 services created: `kubectl get services` shows all ClusterIP services
- [ ] Ingress created: `kubectl get ingress` shows one ingress resource
- [ ] app1.com route works: curl returns "Hello from App One"
- [ ] app2.com route works: curl returns "Hello from App Two"
- [ ] default route works: curl returns "Hello from App Three"

### Common Issues

**Issue:** Services in Pending state
- **Solution:** Traefik ingress controller needs time to initialize. Wait 30 seconds and retry.

**Issue:** curl returns "404 Not Found"
- **Solution:** Ingress not yet loaded. Wait another 15-30 seconds for Traefik to sync.

**Issue:** curl timeout from host machine
- **Solution:** Expected - Vagrant VirtualBox networks are isolated. Test from inside VM instead.

---

## Part 3: K3d Cluster with Argo CD and GitOps

### Overview
- **Goal:** Deploy a **Docker-based K3d cluster** with Argo CD for continuous GitOps deployment
- **Infrastructure:** K3d (1 server + 2 agents, all Docker containers)
- **Namespaces:** argocd (Argo CD system) and dev (application target)
- **Access:** Argo CD UI at http://localhost:8080 (via port-forward)
- **Duration:** ~5-10 minutes (includes Docker container startup)

### Prerequisites
- **Docker** must be installed and running
- `kubectl` installed on host machine
- `k3d` CLI tool (installed by setup_k3d.sh)

### Step-by-Step Setup

```bash
# Navigate to Part 3
cd p3

# Step 1: Create K3d cluster (Docker-based Kubernetes)
echo "Creating K3d cluster (this pulls Docker images, may take 2-3 minutes)..."
bash scripts/setup_k3d.sh

# The script will:
#   1. Create a K3d cluster named "macauchy"
#   2. Configure 1 control plane + 2 worker nodes (as Docker containers)
#   3. Map ports 80 and 443 for ingress
#   4. Create two namespaces: argocd and dev
#   5. Display cluster info

# Wait for K3d cluster to be fully ready
sleep 10

# Verify K3d cluster is running
kubectl get nodes
# Expected output:
#   NAME                STATUS   ROLES                  AGE
#   k3d-macauchy-server-0   Ready    control-plane,master   Xm
#   k3d-macauchy-agent-0    Ready    <none>                 Xm
#   k3d-macauchy-agent-1    Ready    <none>                 Xm

# Verify both namespaces were created
kubectl get namespaces
# Expected: argocd and dev namespaces listed

# Step 2: Install Argo CD
echo "Installing Argo CD (official approach with server-side apply)..."
bash scripts/setup_argocd.sh

# Wait for Argo CD components to start (should complete in ~30 seconds)
# The script will:
#   1. Create argocd namespace (if not exists)
#   2. Apply Argo CD manifests using server-side apply (handles CRD size limits)
#   3. Wait for argocd-server deployment to be ready
#   4. Display admin password

# Verify all Argo CD pods are running
kubectl get pods -n argocd

# Expected output (all should be Running or 1/1 Ready):
#   NAME                                                READY   STATUS
#   argocd-application-controller-0                     1/1     Running
#   argocd-applicationset-controller-xxxxxxxx-xxxxx     1/1     Running
#   argocd-dex-server-xxxxxxxx-xxxxx                    1/1     Running
#   argocd-notifications-controller-xxxxxxxx-xxxxx      1/1     Running
#   argocd-redis-xxxxxxxx-xxxxx                         1/1     Running
#   argocd-repo-server-xxxxxxxx-xxxxx                   1/1     Running
#   argocd-server-xxxxxxxx-xxxxx                        1/1     Running

# Step 3: Deploy test application via Argo CD (GitOps workflow)
echo "Deploying test application via Argo CD..."
kubectl apply -f /vagrant/confs/argocd-app.yaml

# Wait for Argo CD to register the application
sleep 5

# Verify Application resource was created
kubectl get applications -n argocd
# Expected: macauchy-app in argocd namespace

# Verify application pods are being deployed to dev namespace
kubectl get pods -n dev
# Expected: macauchy-app pods should start appearing

# Step 4: Get Argo CD credentials
echo "Getting Argo CD admin password..."
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo

# Step 5: Access Argo CD UI locally
# Option A: Port-forward (recommended for local access)
# In a new terminal:
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Then open in browser:
# https://localhost:8080
# Username: admin
# Password: (from the command above)
# You should now see "macauchy-app" in the Applications section

# Step 6: Verify K3d cluster resources
echo "Verifying K3d cluster..."
kubectl get nodes -o wide
kubectl get pods -A | head -20

# Step 7: View K3d cluster info
# List running K3d clusters
k3d cluster list

# Get K3d cluster kubeconfig
k3d kubeconfig get macauchy

# Step 8: Check application deployment status
echo "Application deployment status:"
kubectl get all -n dev
# Expected: Deployment and Service for macauchy-app running in dev namespace
```

### Verification Checklist

- [ ] Docker is running: `docker ps` shows k3d containers
- [ ] K3d cluster running: `kubectl get nodes` shows 3 nodes (1 server + 2 agents)
- [ ] Namespaces created: `kubectl get ns` shows argocd and dev
- [ ] All Argo CD pods running: `kubectl get pods -n argocd` shows 7 running pods
- [ ] Argo CD server ready: `kubectl rollout status deployment/argocd-server -n argocd`
- [ ] Admin password retrieved: Successfully decoded from secret
- [ ] CRDs installed: `kubectl get crd | grep argoproj` shows 3 CRDs
- [ ] Application deployed: `kubectl get applications -n argocd` shows macauchy-app
- [ ] App pods running: `kubectl get pods -n dev` shows macauchy-app pods
- [ ] UI accessible: Port-forward works and https://localhost:8080 loads
- [ ] App visible in UI: Argo CD dashboard shows macauchy-app with Synced status

### K3d-Specific Details

**What setup_k3d.sh does:**

```bash
# Create K3d cluster with 1 server + 2 agents
k3d cluster create "macauchy" \
  --servers 1 \
  --agents 2 \
  --port "80:80@loadbalancer" \
  --port "443:443@loadbalancer" \
  --api-port 6443 \
  --wait

# Create namespaces
kubectl create namespace argocd
kubectl create namespace dev
```

**Why K3d instead of K3s?**
- **K3d:** Docker-based, runs Kubernetes in containers (perfect for dev/testing)
- **K3s:** Lightweight Kubernetes, runs directly on VMs (production-ready)
- Part 3 uses K3d because:
  - Easier to spin up/tear down for GitOps testing
  - No VM overhead needed
  - Perfect for demonstrating Argo CD workflows
  - Runs multiple nodes in single Docker host

**Managing K3d:**

```bash
# List all K3d clusters
k3d cluster list

# Get kubeconfig for a cluster
k3d kubeconfig get macauchy

# Stop cluster (keeps data)
k3d cluster stop macauchy

# Start cluster again
k3d cluster start macauchy

# Delete cluster (removes everything)
k3d cluster delete macauchy
```

### Configuration Details

**Why `--server-side --force-conflicts` for Argo CD?**
- Kubernetes has a hard limit: metadata.annotations ≤ 262,144 bytes
- Argo CD CRDs exceed this limit in their OpenAPI schema documentation
- Server-side apply handles this by resolving conflicts at the API server level
- This is the **official solution** from Argo CD documentation

### Accessing Argo CD

**Option 1: Port-forward (recommended for local access)**
```bash
# Terminal 1: Start port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Terminal 2: Open in browser
open https://localhost:8080
# or
firefox https://localhost:8080
```

**Option 2: kubectl proxy (alternative)**
```bash
kubectl proxy
# Then access at http://localhost:8001/api/v1/namespaces/argocd/services/argocd-server
```

### Common Issues

**Issue:** Docker daemon not running
- **Solution:** Start Docker: `docker daemon` or open Docker Desktop app

**Issue:** K3d containers fail to start
- **Solution:** Check Docker resources. Ensure host has 4GB RAM available.

**Issue:** ApplicationSet controller in CrashLoopBackOff
- **Solution:** This is normal during initial startup. The controller recovers automatically within 5-10 minutes. All pods eventually stabilize.

**Issue:** Port-forward refuses connection
- **Solution:** Ensure kubectl is pointing to correct cluster: `kubectl cluster-info`

**Issue:** Admin password not showing
- **Solution:** Wait 30 seconds for Argo CD to fully initialize, then run:
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" | base64 -d; echo
  ```

**Issue:** K3d cluster context not in kubeconfig
- **Solution:** The setup script handles this automatically. If needed, manually update:
  ```bash
  k3d kubeconfig merge macauchy --switch-context
  ```

---

## Complete End-to-End Test Sequence

Run this to verify the entire project (requires Docker running for Part 3):

```bash
# Start from project root
cd /home/macauchy/inception_of_things

# ===== PART 1: 2-Node K3s Cluster with Vagrant =====
echo "=== Testing Part 1 (K3s with Vagrant) ==="
cd p1
vagrant up --no-provision  # Boot only (skip provisioning if already done)
vagrant status

# Verify from inside server VM
vagrant ssh macauchyS -c "kubectl get nodes"
vagrant ssh macauchyS -c "kubectl get pods -A | head -10"

# ===== PART 2: 3 Apps with Traefik Ingress (K3s in Vagrant) =====
echo "=== Testing Part 2 (3 Apps with Ingress) ==="
cd ../p2
vagrant status

vagrant ssh macauchyS -c "
  # Deploy if not already deployed
  kubectl apply -f /vagrant/confs/apps.yaml
  kubectl apply -f /vagrant/confs/ingress.yaml
  
  # Test routing
  echo 'Testing app1.com...'
  curl -s -H 'Host: app1.com' http://192.168.56.110/
  
  echo 'Testing app2.com...'
  curl -s -H 'Host: app2.com' http://192.168.56.110/
  
  echo 'Testing default route...'
  curl -s http://192.168.56.110/
"

# ===== PART 3: K3d Cluster with Argo CD (Docker-based) =====
echo "=== Testing Part 3 (K3d + Argo CD) ==="
cd ../p3

# Step 1: Create K3d cluster
echo "Creating K3d cluster..."
bash scripts/setup_k3d.sh

# Step 2: Install Argo CD
echo "Installing Argo CD..."
bash scripts/setup_argocd.sh

# Step 3: Deploy application via Argo CD
echo "Deploying application via Argo CD..."
kubectl apply -f confs/argocd-app.yaml

# Wait for app to deploy
sleep 10
kubectl get pods -n dev

# Step 4: Verify v1 is running
echo "Testing v1 application..."
kubectl port-forward svc/macauchy-app -n dev 8888:8888 &
PF_PID=$!
sleep 2
curl http://localhost:8888/
# Expected: {"status":"ok", "message": "v1"}
kill $PF_PID 2>/dev/null || true

# Step 5: Update to v2 via GitOps
echo "Updating to v2 (simulated local change, normally via Git push)..."
sed -i 's/wil42\/playground:v1/wil42\/playground:v2/g' confs/deployment.yaml

# Step 6: Re-sync the Application
kubectl delete application macauchy-app -n argocd
kubectl apply -f confs/argocd-app.yaml

# Wait for Argo CD to detect and deploy v2
sleep 15
kubectl get pods -n dev

# Step 7: Verify v2 is now running
echo "Testing v2 application..."
kubectl port-forward svc/macauchy-app -n dev 8888:8888 &
PF_PID=$!
sleep 2
curl http://localhost:8888/
# Expected: {"status":"ok", "message": "v2"}
kill $PF_PID 2>/dev/null || true

echo "=== All tests complete ==="
echo ""
echo "To access Argo CD UI:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  Then open https://localhost:8080"
echo "  Username: admin"
echo "  Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
```

# Verify all CRDs
kubectl get pods -n argocd
kubectl get crd | grep argoproj
kubectl get all -n dev

echo "=== GitOps workflow complete ==="
```

---

## Troubleshooting Quick Reference

| Problem | Command to Check | Solution |
|---------|------------------|----------|
| VMs not starting | `vagrant status` | Reboot VirtualBox: `vagrant destroy && vagrant up` |
| kubectl not found | `which kubectl` | SSH into VM: `vagrant ssh macauchyS` |
| Pods pending | `kubectl describe pod <name>` | Wait for node resources, check node status |
| Ingress not routing | `kubectl get ingress -o yaml` | Traefik needs time. Wait 30s, verify rules match |
| Argo CD won't start | `kubectl get pods -n argocd` | Wait 2-3 min or check logs: `kubectl logs -n argocd -l app=...` |
| Port-forward fails | `kubectl cluster-info` | Verify kubeconfig points to correct cluster |

---

## Summary

- **Part 1:** Complete with 2-node K3s cluster
- **Part 2:** Complete with 3 apps and working ingress routing
- **Part 3:** Complete with Argo CD installed and running
- **Total Setup Time:** ~30-45 minutes (mostly waiting for VMs to boot)
- **Testing Time:** ~5-10 minutes

All components are now deployed and functional!
