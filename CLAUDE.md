# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Inception of Things (IoT)** is an educational project on Kubernetes infrastructure focusing on learning K3s and K3d through hands-on Vagrant-based setups. The project consists of three mandatory parts (P1, P2, P3) and one bonus part that progressively deepen understanding of Kubernetes deployment and management.

### Project Structure

- **P1**: Two-node K3s cluster with Vagrant (server + worker architecture)
- **P2**: Single-node K3s with 3 applications and Traefik ingress routing
- **P3**: K3d-based cluster with Argo CD for GitOps (TODO)
- **Bonus**: Gitlab integration with existing infrastructure (TODO)

## Common Commands

### Part 1: Two-Node K3s Cluster

```bash
# Spin up the 2-node cluster
cd p1 && vagrant up

# SSH into server node
vagrant ssh macauchyS

# SSH into worker node
vagrant ssh macauchySW

# Access kubeconfig
export KUBECONFIG=/home/macauchy/inception_of_things/p1/k3s.yaml

# Verify cluster status
kubectl get nodes
kubectl get pods -A

# Destroy and rebuild
vagrant destroy -f && vagrant up
```

### Part 2: Single-Node K3s with Applications

```bash
# Start the cluster
cd p2 && vagrant up

# Deploy applications and ingress
kubectl apply -f confs/apps.yaml
kubectl apply -f confs/ingress.yaml

# Test routing (requires host header)
curl -H 'Host: app1.com' http://192.168.56.110/
curl -H 'Host: app2.com' http://192.168.56.110/
curl http://192.168.56.110/  # Default app

# Check deployments
kubectl get deployments
kubectl get services
kubectl get ingress
```

### Common Kubernetes Operations

```bash
# View logs
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # Follow logs

# Port forwarding
kubectl port-forward svc/<service-name> 8080:80

# Describe resources
kubectl describe pod <pod-name>
kubectl describe node <node-name>

# Delete resources
kubectl delete -f confs/
kubectl delete namespace <namespace>
```

## Architecture & Key Technical Decisions

### Part 1: Two-Node Cluster Architecture

**Network Configuration:**
- Private network (eth1): `192.168.56.x` for inter-node communication
- Server node: `192.168.56.110` (macauchyS)
- Worker node: `192.168.56.111` (macauchySW)
- Flannel CNI explicitly binds to eth1 to ensure proper inter-node communication

**Token Sharing Mechanism:**
- K3s server exposes node token via HTTP on port 8080
- Token server auto-terminates after 10 minutes
- Worker retrieves token with retry logic (60 attempts, 5-second intervals)
- This approach avoids requiring shared folders or NFS since VirtualBox Guest Additions can't be easily installed on AlmaLinux 9

**Key Files:**
- `p1/Vagrantfile`: VM definitions (2 CPUs, 2048 MB RAM each)
- `p1/scripts/setup_server.sh`: K3s server setup with network binding
- `p1/scripts/setup_worker.sh`: K3s agent setup with token fetching
- `p1/k3s.yaml`: Generated kubeconfig for cluster access

### Part 2: Single-Node Cluster with Applications

**Application Architecture:**
- 3 web services deployed using hashicorp/http-echo image:
  - **app-one**: 1 replica, responds with "Hello from App One"
  - **app-two**: 3 replicas (demonstrates horizontal scaling)
  - **app-three**: 1 replica, serves as default/catch-all
- Each deployment has a corresponding ClusterIP service

**Ingress Routing:**
- Uses Traefik ingress controller (built into K3s)
- Host-based routing rules defined in `confs/ingress.yaml`:
  - `app1.com` → app-one
  - `app2.com` → app-two
  - Default/no-host → app-three (catch-all rule)
- Access via `192.168.56.110` with appropriate HTTP Host header

**Nested Virtualization Workaround:**
- VirtualBox 7 requires specific nested virtualization settings to prevent crashes
- Configuration in P2 Vagrantfile disables nested paging and enables KVM paravirtualization

**Key Files:**
- `p2/Vagrantfile`: Single VM definition (2 CPUs, 4096 MB RAM)
- `p2/scripts/setup_server.sh`: Minimal K3s setup
- `p2/confs/apps.yaml`: Application deployments and services
- `p2/confs/ingress.yaml`: Traefik ingress routing rules

### Part 3 & Bonus (Not Yet Implemented)

**Part 3 Goal:**
- Replace Vagrant with K3d (Docker-based K3s for faster iteration)
- Integrate Argo CD for continuous deployment
- Create namespaces: `argocd` (system), `dev` (applications)
- Synchronize apps from public GitHub repository via GitOps

**Bonus Goal:**
- Add local Gitlab instance to the infrastructure
- Integrate Gitlab with P3 setup
- Requires Helm and advanced configuration

## Git Workflow

- **Branch**: Work on `main` branch
- **Commit Style**: Follow conventional commits format
  - Examples: `fix(p1): resolve K3s inter-node networking`, `feat(p2): add ingress configuration`
- **Sensitive Files**: Kubeconfig, node tokens, and other sensitive data are in `.gitignore` and should never be committed

## Important Notes

- **VMs use AlmaLinux 9** base image with minimal setup
- **Token-based authentication** between server and worker (Part 1) requires the server to be running when workers are provisioned
- **Kubeconfig**: Required to run kubectl commands against the cluster. Set via `export KUBECONFIG=p1/k3s.yaml`
- **Vagrant SSH keys**: Configured for password-less access between VMs and host
- **Image sources**: Uses public container images (hashicorp/http-echo) from Docker Hub

## Project Requirements Reference

See `new_subject.md` for complete project specification including:
- Exact VM and network configurations
- Expected output and testing procedures
- Part-specific requirements and acceptance criteria
