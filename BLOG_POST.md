# Inception of Things: A Complete Guide to Kubernetes Infrastructure from Scratch to GitOps

**Published:** January 2026
**Author:** Learning through Implementation
**Reading Time:** 90 minutes (comprehensive with glossary)
**Difficulty:** Beginner → Advanced
**Topics:** Kubernetes, K3s, K3d, Vagrant, Argo CD, GitOps, Infrastructure as Code

---

## Quick Navigation

- **Absolute Beginner?** → Start with [Glossary & Jargon Breakdown](#glossary--jargon-breakdown)
- **Know some Docker/Linux?** → Start with [What This Project Teaches](#what-this-project-teaches)
- **Familiar with Kubernetes?** → Jump to [Part 3: GitOps with Argo CD](#part-3-gitops-with-argo-cd)
- **Getting an error?** → Go to [Common Pitfalls & Solutions](#common-pitfalls--solutions)

---

## Table of Contents

1. [Glossary & Jargon Breakdown](#glossary--jargon-breakdown)
2. [Introduction](#introduction)
3. [What This Project Actually Teaches](#what-this-project-teaches)
4. [Prerequisites & Setup](#prerequisites--setup)
5. [Part 1: Building Your First Multi-Node K3s Cluster](#part-1-building-your-first-multi-node-k3s-cluster)
6. [Part 2: Running Applications on Kubernetes](#part-2-running-applications-on-kubernetes)
7. [Part 3: GitOps with Argo CD](#part-3-gitops-with-argo-cd)
8. [Common Pitfalls & Solutions](#common-pitfalls--solutions)
9. [Reflections & Key Learnings](#reflections--key-learnings)
10. [Going Deeper](#going-deeper)
11. [Practical Command Reference](#practical-command-reference)

---

## Glossary & Jargon Breakdown

### Essential Terminology (Beginner Level)

#### **Container**
**What:** A standardized package containing your application, its dependencies, libraries, and configuration.

**Why:** Before containers, deploying software was nightmare. "Works on my machine but not on the server" was a common phrase. Containers solve this by bundling everything the app needs.

**Analogy:** Shipping container. Just like a physical shipping container is the same whether it's on a truck, ship, or train, a Docker container works identically on your laptop, test server, or production server.

**Example:**
```bash
# Without containers: "Install Python 3.10, pip install requests, set ENV vars..."
# With containers: "docker run python:3.10"
# The container already has everything configured
```

---

#### **Docker**
**What:** Software that builds, runs, and manages containers. It's the most popular container technology.

**Why:** Docker makes containers practical. Without it, containers would exist but be hard to use.

**Beginner Understanding:** Docker = container factory
- `docker build` = create a container image (recipe)
- `docker run` = start a container (cook from recipe)
- `docker push` = upload to Docker Hub (share recipe)

**Professional Understanding:** Docker uses Linux kernel features (namespaces, cgroups) to isolate processes while sharing the kernel. This is why it's faster than VMs.

---

#### **Virtual Machine (VM)**
**What:** A complete simulation of a computer, running its own operating system and applications independently.

**Why:** Allows running multiple operating systems on one physical computer. Useful for testing, isolation, and development.

**Beginner Understanding:** VM = full computer in software
- Requires full OS (bootable, 1-5 GB)
- Takes minutes to start
- Uses significant RAM (per OS)

**Professional Understanding:** VMs use hypervisors (Type 1: bare-metal like Hyper-V, or Type 2: hosted like VirtualBox) to virtualize CPU, memory, disk, and network. More overhead than containers but better isolation.

---

#### **Kubernetes (K8s)**
**What:** A container orchestration system. It manages, scales, and deploys containers across multiple machines automatically.

**Why:** When you have 100 containers running, you can't manage them manually. Kubernetes automates this.

**Beginner Understanding:** Kubernetes = container manager
- You tell it "I want 5 copies of my app running"
- Kubernetes ensures 5 are always running
- If one crashes, Kubernetes replaces it

**Professional Understanding:** Kubernetes is a control plane + worker architecture running containerized workloads. It provides declarative configuration, self-healing, rolling updates, and resource management. It's extensible via CRDs and has a rich ecosystem.

---

#### **K3s**
**What:** A lightweight, simplified version of Kubernetes designed for edge computing, IoT, and learning.

**Why:** Full Kubernetes is complex (~200 GB of documentation). K3s keeps the essential features while being learnable.

**Key Difference from K8s:**
- Full Kubernetes: ~500 MB, complex, enterprise-ready
- K3s: ~100 MB, simple, learning-friendly
- Both speak the same language (kubectl commands work identically)

**Beginner:** "K3s is Kubernetes lite"
**Professional:** K3s bundles container runtime, networking, storage into single binary. Removes alpha APIs and reduces dependencies.

---

#### **K3d**
**What:** A tool that runs K3s clusters inside Docker containers instead of VMs.

**Why:** K3s in Docker = super fast. Spin up a 3-node cluster in 10 seconds instead of 3 minutes.

**Comparison:**
```
K3s on Vagrant (Part 1-2):
  Vagrant → VirtualBox VM → Linux → K3s → Containers
  Complexity: High, Speed: 3-5 minutes

K3d (Part 3):
  K3d → Docker Container → K3s → Containers
  Complexity: Low, Speed: 10-30 seconds
```

---

#### **Container Image**
**What:** A static, read-only template describing how to create a container.

**Why:** You need a recipe before you can cook. Images are the recipes.

**Beginner Understanding:**
```bash
docker run ubuntu:22.04
# Downloads the ubuntu:22.04 image
# Creates a container from it
# Starts it

# Image: the file on disk (the recipe)
# Container: the running process (the cooked meal)
```

**Professional Understanding:** Images are layered (union filesystem). Each layer is immutable. When you build an image, you create new layers on top of a base image. This enables caching and efficient storage.

---

#### **Deployment**
**What:** A Kubernetes resource describing how to run containers. It specifies replicas, resources, health checks, and update strategy.

**Why:** Ensures containers run reliably. Replaces old pods when updating, heals failed pods automatically.

**Beginner Understanding:** "I want 3 copies of my app running, always"

**YAML Example:**
```yaml
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3          # Always run 3 copies
  template:            # Template for each pod
    spec:
      containers:
      - name: app
        image: my-app:v1  # What image to run
```

---

#### **Pod**
**What:** The smallest deployable unit in Kubernetes. Usually contains one container (sometimes multiple tightly-coupled containers).

**Why:** Kubernetes can't run bare containers. Pods wrap containers and provide networking, storage, and lifecycle management.

**Beginner Understanding:** Pod ≈ Container (they're almost the same, Pod is just the K8s wrapper)

**Professional Understanding:** Pods are ephemeral (short-lived). They share network namespace, have shared storage, and are tightly coupled. Multiple containers in one pod share network (localhost) and storage but not compute.

---

#### **Service**
**What:** A Kubernetes resource that creates a stable network endpoint for accessing pods.

**Why:** Pods die and respawn. Services provide a consistent IP/DNS name.

**Beginner Understanding:** "How do I access my pod when it keeps crashing and respawning?"

**Answer:** Service routes traffic to whatever pods are alive.

**Example:**
```yaml
kind: Service
metadata:
  name: my-app-service
spec:
  selector:
    app: my-app      # Route to pods with this label
  ports:
  - port: 80         # Service port
    targetPort: 8080 # Pod container port
```

Clients connect to `my-app-service:80`, service forwards to any pod with `app: my-app` label on port 8080.

---

#### **Ingress**
**What:** A Kubernetes resource for routing external HTTP/HTTPS traffic to services based on hostnames or paths.

**Why:** Services are internal. Ingress exposes apps to the internet and provides hostname-based routing.

**Beginner Understanding:** "I want example.com → my-app, api.example.com → my-api"

---

#### **Namespace**
**What:** A logical partition within a cluster, providing isolated environments and resource quotas.

**Why:** Multiple teams/apps need isolation. Namespaces prevent them from interfering.

**Example:**
```bash
kubectl create namespace dev
kubectl create namespace prod

# Objects in different namespaces don't interact
# dev-app can't see prod-app

# Run pods in specific namespace:
kubectl run my-pod --namespace=dev
```

---

### Intermediate Jargon (For Those With Some Experience)

#### **Declarative vs Imperative Configuration**

**Imperative (Old Way):**
```bash
# "Do these steps"
kubectl run my-app --image=my-app:v1
kubectl expose deployment my-app --port=80
kubectl scale deployment my-app --replicas=3
```
Problems: Hard to track changes, not version-controlled, not reproducible

**Declarative (Modern Way):**
```yaml
# "This is the desired state"
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: app
        image: my-app:v1
```
Benefits: Version-controlled, reproducible, diffable, reviewable

---

#### **Reconciliation Loop**
**What:** Kubernetes continuously checking actual state vs desired state and fixing differences.

**Why:** Self-healing. If you specify "3 replicas" and a pod dies, K8s creates a replacement.

**Beginner Understanding:** K8s is always asking "Is the cluster in the desired state? If not, fix it."

**Professional Understanding:** This is the core principle enabling Kubernetes's reliability. Controllers implement this loop for different resources (Deployment controller, StatefulSet controller, etc.).

---

#### **Custom Resource Definition (CRD)**
**What:** A way to extend Kubernetes with custom resource types beyond built-in ones.

**Why:** Kubernetes only has Deployment, Service, etc. Some apps need special types (e.g., Argo CD defines "Application" as a CRD).

**Example:**
```yaml
# Standard Kubernetes resource
kind: Deployment

# Custom resource (defined by Argo CD)
kind: Application
```

---

#### **Helm**
**What:** A package manager for Kubernetes, like `apt` for Linux or `npm` for Node.

**Why:** Writing YAML manually is tedious. Helm provides pre-made templates (charts).

**Beginner Understanding:** Instead of hand-writing Postgres Deployment YAML:
```bash
helm install postgres bitnami/postgresql
# Deploys Postgres with best practices
```

**Professional Understanding:** Helm uses Go templates for YAML, provides versioning, dependency management, and rollback capabilities. Charts can be shared via Helm repositories.

---

#### **Kustomize**
**What:** A native K8s templating tool (built into kubectl) for managing YAML variations.

**Why:** You have dev/prod/staging environments with slight differences. Kustomize manages these variations.

**Example:**
```
base/
  deployment.yaml
overlays/
  dev/
    kustomization.yaml (override replicas: 1)
  prod/
    kustomization.yaml (override replicas: 5)
```

---

#### **ConfigMap and Secret**
**What:** Ways to inject configuration and sensitive data into pods.

**Why:** Apps need configuration. You don't hardcode credentials in container images.

**ConfigMap:** Non-sensitive configuration
```yaml
kind: ConfigMap
metadata:
  name: app-config
data:
  DATABASE_URL: "postgres://db:5432/mydb"
  LOG_LEVEL: "debug"
```

**Secret:** Sensitive data (base64 encoded, encrypted at rest)
```yaml
kind: Secret
metadata:
  name: app-secrets
data:
  API_KEY: base64(actual-key)
  PASSWORD: base64(actual-password)
```

---

#### **RBAC (Role-Based Access Control)**
**What:** Kubernetes authorization system controlling what users/services can do.

**Why:** Security. You don't want developers deleting production database pods.

**Example:**
```yaml
kind: Role
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
# User with this role can read pods but not delete
```

---

### Advanced Jargon (Professional Level)

#### **Control Plane vs Data Plane**
**Control Plane:** API server, etcd, scheduler, controllers. Makes decisions.

**Data Plane:** Worker nodes running containers. Executes decisions.

**Understanding:** Control plane says "I want 3 pods," data plane runs them.

---

#### **Operators**
**What:** Kubernetes extensions that automate complex, stateful applications.

**Why:** Some apps need custom logic (e.g., database failover, backup scheduling). Operators encode this logic.

**Example:** Prometheus Operator watches PrometheusOperator CRD, automatically creates Prometheus instances, configures scraping targets, manages RBAC.

---

#### **Service Mesh**
**What:** A dedicated infrastructure layer managing service-to-service communication.

**Why:** As systems scale, managing inter-service communication becomes complex. Service mesh (Istio, Linkerd) handles this transparently.

**Capabilities:** Load balancing, circuit breaking, canary deployments, mTLS, observability.

---

#### **GitOps**
**What:** Operational model where Git is the source of truth for desired state.

**Why:** Combines benefits of Git (version control, audit trail, review process) with Kubernetes (automated enforcement).

**Flow:**
```
You commit to Git
  ↓
GitOps controller (e.g., Argo CD) detects change
  ↓
Controller applies manifests to cluster
  ↓
Cluster converges to Git state
  ↓
Everything is auditable via Git history
```

---

#### **Admission Controllers**
**What:** Webhooks that validate or mutate Kubernetes objects before they're stored.

**Why:** Enforce policies. Reject pods not running as non-root, auto-inject sidecars, validate labels.

---

## Introduction

When I first encountered this project, I thought it was simply "set up Kubernetes clusters and deploy some apps." Six months later, I realize it's actually a **masterclass in modern infrastructure automation**.

This guide documents the complete journey of building three progressively sophisticated Kubernetes environments, starting with bare-metal VMs and ending with a fully automated GitOps pipeline. By the end, you'll understand not just *how* to run Kubernetes, but *why* modern DevOps practices are structured the way they are.

### What Problem Are We Solving?

In 2024, here's the reality of infrastructure:

**Manual deployments are dead** - They're error-prone, undocumented, and don't scale
- Deploying via SSH and shell commands is slow
- Changes aren't tracked (what changed? when? why?)
- Disasters happen when someone makes a typo
- New team members don't know the history

**Infrastructure as Code is essential** - Everything should be version-controlled and reproducible
- Your infrastructure is code (Vagrantfiles, YAML manifests)
- It's in Git (full history, blame, rollback)
- It's reviewed (pull requests, CI/CD)
- It's tested (dry-runs, staging environments)

**Kubernetes is the standard** - But it's complex, and learning it properly matters
- Container orchestration is the modern baseline
- Understanding it deeply opens career opportunities
- Getting it wrong costs real money in operational overhead

**GitOps is the future** - Your Git repository becomes your single source of truth
- Deployments are automated from Git
- Rollback is `git revert`
- Disaster recovery is `git checkout <good-commit>`
- Everything is auditable

This project takes you through each concept, building from simple (single VM) to sophisticated (multi-node cluster with GitOps automation).

---

## What This Project Actually Teaches

### Technical Skills You'll Develop

**Infrastructure Automation**
- Writing Vagrantfiles that describe VMs as code
- Automating VM provisioning with bash scripts
- Understanding networking between VMs
- Creating reproducible infrastructure

**Kubernetes Fundamentals**
- Installing and configuring K3s (why lightweight K8s matters)
- Creating Deployments (managing multiple pod replicas)
- Creating Services (exposing pods via network endpoints)
- Creating Ingress rules (routing external traffic)
- Understanding Namespaces (logical isolation)

**Container Orchestration**
- Scaling applications (replicas)
- Self-healing (K8s restarts crashed pods)
- Rolling updates (deploy new versions without downtime)
- Resource management (CPU, memory limits)

**Modern DevOps Practices**
- Infrastructure as Code (IaC) - infrastructure in version control
- Continuous Deployment (CD) - automatic deployments
- GitOps workflows - Git as single source of truth
- Configuration management - ConfigMaps and Secrets

**Practical Development**
- Git workflows (commits, branches, merges)
- Shell scripting best practices
- Debugging Kubernetes issues
- Testing deployments

### Learning Progression: From Confusion to Understanding

**Part 1: "I can create and configure VMs"**
- What you learn: Vagrant, VM networking, K3s basics
- What you build: 2-node Kubernetes cluster
- Aha moment: Infrastructure can be described as code!

**Part 2: "I can run applications on Kubernetes"**
- What you learn: Deployments, Services, Ingress
- What you build: Single-node cluster with 3 apps and routing
- Aha moment: Kubernetes automatically manages apps for me!

**Part 3: "I can automate deployments from Git"**
- What you learn: K3d, Argo CD, GitOps
- What you build: Automated deployment pipeline
- Aha moment: I never have to manually deploy again!

---

## Prerequisites & Setup

### Required Software (What Each One Does)

**Vagrant** (Infrastructure provisioning tool)
- **What:** Describes VMs in code (Vagrantfile)
- **Why:** Reproducible infrastructure, version control friendly
- **Check installation:** `vagrant --version` (need 2.4.0+)

**VirtualBox** (Hypervisor - VM software)
- **What:** Software that runs VMs
- **Why:** Free, cross-platform, integrates with Vagrant
- **Check installation:** `virtualbox --version` (need 7.0+)

**Git** (Version control)
- **What:** Tracks changes to files
- **Why:** Track infrastructure and application code
- **Check installation:** `git --version` (need 2.40+)

**Docker** (Container runtime)
- **What:** Builds and runs containers
- **Why:** Part 3 uses K3d which requires Docker
- **Check installation:** `docker --version` (need 20.10+)

**kubectl** (Kubernetes CLI)
- **What:** Command-line tool to interact with Kubernetes
- **Why:** Deploy and manage applications
- **Check installation:** `kubectl version --client` (automatic for Part 1)

---

## Part 1: Building Your First Multi-Node K3s Cluster

### What We're Building

**Goal:** Create two virtual machines that communicate with each other and form a Kubernetes cluster.

**Architecture:**
```
┌─────────────────────────────────────────────┐
│           Host Machine (Your Computer)      │
│                                             │
│  ┌────────────────────────────────────┐     │
│  │  VirtualBox (VM Software)          │     │
│  │                                    │     │
│  │  ┌──────────────────────────────┐  │     │
│  │  │  VM 1: macauchyS (Server)    │  │     │
│  │  │  - IP: 192.168.56.110        │  │     │
│  │  │  - K3s: Control Plane        │  │     │
│  │  └──────────────────────────────┘  │     │
│  │                                    │     │
│  │  ┌──────────────────────────────┐  │     │
│  │  │  VM 2: macauchySW (Worker)   │  │     │
│  │  │  - IP: 192.168.56.111        │  │     │
│  │  │  - K3s: Worker Node          │  │     │
│  │  └──────────────────────────────┘  │     │
│  └────────────────────────────────────┘     │
│                                             │
│  Both VMs connected via private network     │
│  (192.168.56.x)                             │
└─────────────────────────────────────────────┘
```

> **⚠️ Note:** When you run `vagrant up`, if the VM crashes with a VirtualBox hypervisor error, don't panic! This has been encountered and fixed. See [Issue 4: VirtualBox Hypervisor Crashes](#issue-4-virtualbox-hypervisor-crashes-during-provisioning) in the troubleshooting section for solutions.

### Understanding Vagrant: Infrastructure as Code

**What is Vagrant?**
- Tool that automates VM creation
- Instead of clicking VirtualBox buttons, you write code
- `vagrant up` creates all VMs with proper configuration

**Why Use Vagrant?**
- **Reproducibility:** Run same file 100 times, get identical VMs
- **Version Control:** Vagrantfile goes in Git
- **Documentation:** Vagrantfile documents infrastructure
- **Simplicity:** Complex setup becomes single command

**Without Vagrant (old way):**
1. Open VirtualBox
2. Click "Create VM"
3. Select OS image
4. Configure memory, CPU
5. Configure networking
6. Boot VM
7. SSH and run setup scripts
8. Repeat for second VM
9. Fix networking issues
10. Try to remember what you did

**With Vagrant (new way):**
```bash
vagrant up
# Done in 5 minutes, fully automated and repeatable
```

### The Vagrantfile: Part by Part

**What is a Vagrantfile?**
- Ruby script describing VMs
- Read by Vagrant to create infrastructure
- Goes in root of project directory

**Why Ruby?**
- Simple syntax
- Can contain logic (loops, conditionals)
- Mature language with good tooling

```ruby
# p1/Vagrantfile
Vagrant.configure("2") do |config|
  # "2" means Vagrant API version 2 (current stable)
  # |config| is the object you configure

  config.vm.box = "almalinux/9"
  # Which OS to use. "almalinux/9" is AlmaLinux 9
  # Vagrant downloads this from Vagrant Cloud automatically

  config.vm.provider "virtualbox"
  # Use VirtualBox as the hypervisor (not Hyper-V, VMware, etc.)

  config.vm.boot_timeout = 600
  # Wait 10 minutes for VM to boot (nested virt is slow)

  config.vm.synced_folder ".", "/vagrant", disabled: true
  # Don't sync host folder to VM
  # Why disabled? AlmaLinux doesn't have VirtualBox Guest Additions
  # which would be needed for synced folders
```

**Defining the Server VM:**

```ruby
LOGIN = "macauchy"  # Your username
SERVER_IP = "192.168.56.110"  # Fixed IP for server
WORKER_IP = "192.168.56.111"  # Fixed IP for worker

config.vm.define "#{LOGIN}S" do |server|
  # Define a VM named "macauchyS" (LOGIN + "S" for Server)

  server.vm.hostname = "#{LOGIN}S"
  # Set the hostname inside the VM to "macauchyS"

  server.vm.network "private_network", ip: "#{SERVER_IP}"
  # Create a private network (192.168.56.x range)
  # Assign this VM IP 192.168.56.110
  # This is how VMs communicate with each other and host

  server.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"  # 2GB RAM
    vb.cpus = 2         # 2 CPU cores
    vb.name = "#{LOGIN}S"  # VirtualBox VM name (in GUI)
  end

  server.vm.provision "shell", path: "scripts/setup_server.sh"
  # After VM boots, run this script to install K3s
end
```

**Why These Specific IPs?**

The IP range `192.168.56.0/24` is special:
- RFC 1918 designated private IP range
- Used by VirtualBox's default isolated network
- Means: Host can access VMs, VMs can access each other
- Host IP is 192.168.56.1, server gets 110, worker gets 111

**Why Two Separate Machines?**

This teaches you multi-node Kubernetes:
- Real K8s has multiple nodes
- You learn about networking, distributed systems
- Part 2 simplifies to single-node to focus on apps

### K3s Installation Deep Dive

**What is K3s?**
- **K3s** = Kubernetes (K + 8 letters + s) lightweight version
- Full Kubernetes but with some advanced features removed
- Perfect for learning and edge computing

**Why K3s and not Full Kubernetes?**
- Full K8s: ~500 MB, complex, requires lots of resources
- K3s: ~100 MB, simple, runs on anything
- Both use identical kubectl commands
- Easier to learn, same concepts

**The Installation Script:**

```bash
#!/bin/bash
set -e  # Exit on any error

echo "=== Installing K3s Server ==="

# The K3s installation happens in one line:
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC="\
    --node-ip=192.168.56.110 \
    --advertise-address=192.168.56.110 \
    --flannel-iface=eth1" sh -
```

**What happens here? (Step by step)**

1. `curl -sfL https://get.k3s.io`
   - Downloads K3s installer script from internet
   - `-s` = silent, `-f` = fail on error, `-L` = follow redirects

2. `| sh -`
   - Pipes directly to bash (executes the script)
   - This is how K3s distribution works

3. Environment variables:
   - `INSTALL_K3S_EXEC="--node-ip=192.168.56.110"`
   - Tells K3s to listen on the private network IP
   - Without this, K3s might bind to localhost (unreachable from other VMs)

4. `--advertise-address=192.168.56.110`
   - When other nodes connect, this is the IP they use
   - Must match the IP they can reach (the private network)

5. `--flannel-iface=eth1`
   - Flannel is K3s's default network plugin
   - `eth1` is the private network interface (on older systems)
   - Modern Linux distributions use predictable interface names like `enp0s8`, `enp0s9` instead of `eth0`, `eth1`
   - Without this, Flannel might use the wrong interface
   - **Note:** Our scripts auto-detect the interface name, so it works on any system

**Why is this complex?**

Modern systems have multiple network interfaces:
- `lo` (localhost, only VM itself)
- `eth0` or `enp0s3` (NAT, VM to host)
- `eth1` or `enp0s8` (private network, VM to VM) ← This one is critical for K3s

Kubernetes needs to know which interface to use. You must tell it. The setup scripts automatically detect your system's interface names, so you don't need to manually specify them.

### The Token Sharing Mechanism

**Problem:** Worker needs to authenticate with server. How do we pass credentials?

**Traditional approach:** Shared NFS folder
- Simple but requires Guest Additions (hard on AlmaLinux)

**Our approach:** HTTP server
- Clever and requires no special setup

```bash
# Server creates token file
TOKEN_FILE="/var/lib/rancher/k3s/server/node-token"

# Wait for it to exist
while [ ! -f "$TOKEN_FILE" ]; do
  echo "Waiting for token..."
  sleep 2
done

# Create temp directory and copy token there
TOKEN_DIR=$(mktemp -d)
cp "$TOKEN_FILE" "$TOKEN_DIR/node-token"
cd "$TOKEN_DIR"

# Start Python HTTP server
nohup python3 -m http.server 8080 --bind 192.168.56.110 &

# Clean up after 10 minutes
(sleep 600 && pkill -f "http.server 8080") &
```

**How worker gets the token:**

```bash
# Worker script
TOKEN=$(curl -sf "http://192.168.56.110:8080/node-token")

# Use token to join cluster
curl -sfL https://get.k3s.io | \
  K3S_URL=https://192.168.56.110:6443 \
  K3S_TOKEN=$TOKEN \
  INSTALL_K3S_EXEC="--node-ip=192.168.56.111" sh -
```

**Why this works:**
- `K3S_URL=https://192.168.56.110:6443` = where to find the server
- `K3S_TOKEN=$TOKEN` = authentication credentials
- Server is already running, token server is active
- Worker downloads K3s and joins the cluster

**Why auto-cleanup after 10 minutes?**
- Token server is a security risk (exposes credentials)
- Worker should get token quickly
- 10 minutes is plenty of time for worker to boot and fetch
- After that, server doesn't need the token server anymore

### Running Part 1: Step by Step

```bash
cd p1

# 1. Create both VMs and provision them
vagrant up

# This will:
# - Download AlmaLinux 9 image (1GB, first time only)
# - Create VM named "macauchyS" with 2GB RAM, 2 CPUs
# - Create VM named "macauchySW" with 2GB RAM, 2 CPUs
# - Boot both VMs
# - Run setup_server.sh on server
# - Run setup_worker.sh on worker
# - Worker will retry 60 times to get token from server
# - Both will install K3s and join cluster
# Takes 3-5 minutes first time

# 2. Check status
vagrant status
# Should show both VMs running

# 3. SSH into server
vagrant ssh macauchyS

# 4. Inside the VM, check Kubernetes
kubectl get nodes

# Output should be:
# NAME        STATUS   ROLES              AGE   VERSION
# macauchyS   Ready    control-plane      30s   v1.31.5+k3s1
# macauchySW  Ready    <none>             15s   v1.31.5+k3s1

# Both Ready = cluster is healthy!

# 5. Check the kubeconfig (authentication credentials)
cat /etc/rancher/k3s/k3s.yaml

# 6. Exit the VM
exit

# 7. On your host, access the cluster using kubeconfig
export KUBECONFIG=$PWD/p1/k3s.yaml
kubectl get nodes

# Should show the same nodes from your host!
```

### Crucial Concepts Explained

**What is kubeconfig?**
- Configuration file telling kubectl where the cluster is
- Contains:
  - Server address (https://192.168.56.110:6443)
  - Client certificates (authentication)
  - Context settings
- Without it, kubectl doesn't know which cluster to talk to

**What is a node?**
- A machine (VM or physical) in the cluster
- Can be control plane (manager) or worker (runs apps)
- macauchyS is control plane (has roles: control-plane, master)
- macauchySW is worker (no roles, just runs containers)

**What is a control plane?**
- Machines that manage the cluster
- Run API server (what kubectl talks to)
- Run scheduler (decides where to run pods)
- Run controllers (fix things when they break)
- Usually 1-3 nodes for high availability

**What are workers?**
- Machines that run your applications
- Listen to control plane
- Run containers
- Can be scaled up/down

### Common Pitfalls in Part 1

**Issue 1: Worker stuck in "NotReady"**

```bash
# Inside worker VM:
vagrant ssh macauchySW

# Check if it's still trying to get token
ps aux | grep curl

# Check networking
ping 192.168.56.110
# If this fails, networking is broken

# Check the logs
journalctl -u k3s-agent -n 50 --no-pager

# Common causes:
# 1. Server not ready yet (wait a bit longer)
# 2. Token server not running (check server VM)
# 3. Network not configured (Vagrant issue)
# 4. Token server already stopped (after 10 minutes)
```

**Solution:** If stuck, restart the worker:
```bash
vagrant reload macauchySW
# This will reboot the VM and try again
```

**Issue 2: Vagrant up hangs**

```bash
# If it hangs on "Running scripts", check what's happening
vagrant ssh macauchyS

# See if K3s is still installing
ps aux | grep k3s
tail /var/log/k3s-install.log

# K3s downloads are slow (pulling container images)
# On slow internet, this can take 5-10 minutes
# Be patient!
```

**Issue 3: kubeconfig has wrong IP**

```bash
# If kubeconfig says "server: https://127.0.0.1:6443"
# But you're on a different machine, it won't work

# Fix it:
sed -i 's/127.0.0.1/192.168.56.110/g' p1/k3s.yaml

# Or manually edit:
vim p1/k3s.yaml
# Change: server: https://127.0.0.1:6443
# To: server: https://192.168.56.110:6443
```

**Issue 4: VirtualBox Hypervisor Crashes During Provisioning**

This was a major issue we encountered during development. If `vagrant up` suddenly crashes with "A critical error has occurred," here's what was happening and how we fixed it.

**What happened:**
```
vagrant up
... some output ...
[VM suddenly crashes]
The VirtualBox VM was killed by the hypervisor
```

**Root causes we discovered:**

The setup scripts were doing things that caused VirtualBox to crash during provisioning:

1. **Complex text processing pipelines** - Using many piped commands like:
   ```bash
   # ❌ This caused crashes:
   ip link show | grep -E "^[0-9]+:" | grep -v lo | awk -F: '{print $2}' | sed 's/.../' | tail -1
   ```
   Each pipe adds overhead, and during provisioning the hypervisor would become unstable.

2. **Aggressive network configuration** - Trying to forcefully change network settings via `nmcli`:
   ```bash
   # ❌ This caused crashes:
   nmcli conn down eth1
   nmcli conn up eth1
   ```
   Network interface cycling during VM provisioning triggers hypervisor instability.

3. **Complex file operations** - Embedding Python YAML parsers in shell heredocs caused permission issues and resource contention.

**How we fixed it:**

We simplified everything to the absolute minimum:

```bash
# ✅ This is stable:
for iface in eth1 enp0s8 enp0s9 enp0s10; do
    if ip link show "$iface" &>/dev/null; then
        INTERFACE="$iface"
        break
    fi
done
```

This approach:
- Checks interface existence before trying to use it
- Supports both legacy (eth1) and modern (enp0s8) interface names
- Reduces system load during provisioning
- Is explicit and easy to debug

**Key learnings:**

When writing Vagrant provisioning scripts:
1. Keep them **as simple as possible**
2. Avoid complex command pipelines
3. Never manipulate network state aggressively
4. Use basic shell commands only (no embedded Python/Ruby)
5. Test locally before deploying

**If you hit a crash:**

```bash
# 1. Clean up completely
vagrant destroy -f
rm -rf .vagrant

# 2. Try again
vagrant up

# 3. If it crashes again, check:
# - Host has enough resources (4GB+ RAM free)
# - Disk space is available (1GB+ free)
# - No other VMs running
# - VirtualBox version is 7.0+
```

---

## Part 2: Running Applications on Kubernetes

### What We're Building

**Goal:** Single K3s cluster running 3 different web applications, accessible by hostname.

**The Concept:**
```
User requests → 192.168.56.110 (host: app1.com)
               ↓
         Ingress Controller (Traefik)
               ↓
         "app1.com → send to app-one-svc"
               ↓
         Service app-one-svc
               ↓
         Pod with "app: app-one" label
               ↓
         Container responding with "Hello from App One"
```

### Single-Node vs Multi-Node: Why the Change?

**Part 1:** Two-node cluster
- Teaches networking, clustering, multi-node concepts
- More complex setup
- Demonstrates real production patterns

**Part 2:** Single-node cluster
- Focuses on application deployment
- Simpler to understand
- Still demonstrates Kubernetes concepts
- K3s handles everything on one machine

**Real-world:** Most dev environments use single-node (easier). Production uses multi-node (reliability).

### Kubernetes Manifests: The YAML Files

**What is a manifest?**
- YAML file describing Kubernetes resources
- Declarative (you describe desired state, K8s achieves it)
- Version-controlled (lives in Git)
- Self-documenting

**Why YAML?**
- Human-readable
- Less verbose than JSON
- Supports comments
- Standard in Kubernetes ecosystem

### Deployments: Managing Replicas

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-one
spec:
  replicas: 1
  # ↑ "Always run exactly 1 copy of this app"
  # If pod crashes, K8s restarts it
  # If you change to 3, K8s creates 2 more

  selector:
    matchLabels:
      app: app-one
  # ↑ Deployment finds pods with label "app: app-one"
  # This is how deployment knows which pods are its

  template:
    metadata:
      labels:
        app: app-one
    # ↑ New pods get this label
    # Deployment will find them via selector above

    spec:
      containers:
      - name: app-one
        image: hashicorp/http-echo
        # Image to run (from Docker Hub)

        args: ["-text=Hello from App One"]
        # Arguments passed to the container
        # This specific image echoes the text

        ports: [{ containerPort: 5678 }]
        # Container listens on this port inside pod
```

**What Happens When You Apply This:**

```bash
kubectl apply -f deployment.yaml

# K8s creates:
# 1. ReplicaSet (manages replicas)
# 2. Pod (running container)
# 3. Labels for tracking

# K8s promises:
# - "Always 1 replica"
# - If pod crashes, create new one
# - If node dies, recreate pod elsewhere
# - If you scale to 3, create 2 more immediately

# This is self-healing!
```

### Services: Stable Endpoints

**Problem:** Pods die and respawn with new IPs. How do you access them reliably?

**Answer:** Services provide a stable endpoint that load-balances to live pods.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-one-svc
spec:
  selector:
    app: app-one
  # ↑ Forward traffic to pods with label "app: app-one"

  ports:
  - port: 80
    targetPort: 5678
  # ↑ Service port 80 → Container port 5678

  type: ClusterIP
  # Default type (internal to cluster)
```

**How It Works:**

```
Client → Service IP:80
          ↓ (service load-balances)
          Pod 1:5678 (if alive)
          Pod 2:5678 (if alive)
          Pod 3:5678 (if alive)

Service automatically:
- Discovers which pods are healthy
- Load-balances across them
- Updates if pods are added/removed
```

**Service DNS:**
Within the cluster, you can access by name:
```bash
# From inside a pod:
curl http://app-one-svc:80
# DNS resolves app-one-svc to service IP
# Service load-balances to actual pods
```

### Ingress: Routing External Traffic

**Problem:** Services are cluster-internal. Users on the internet need to access apps.

**Solution:** Ingress routes external HTTP/HTTPS traffic to services.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: main-ingress
spec:
  ingressClassName: traefik
  # K3s comes with Traefik (no installation needed!)

  rules:
  - host: app1.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-one-svc
            port: { number: 80 }
  # ↑ If request Host: app1.com → send to app-one-svc

  - host: app2.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-two-svc
            port: { number: 80 }
  # ↑ If request Host: app2.com → send to app-two-svc

  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-three-svc
            port: { number: 80 }
  # ↑ No host specified = catch-all default
  # If Host doesn't match above, use this
```

**Ingress Flow:**

```
External Request to 192.168.56.110
   ↓ (checks Host header)
   ├─ Host: app1.com → app-one-svc
   ├─ Host: app2.com → app-two-svc
   └─ Other → app-three-svc
   ↓ (service load-balances)
   Pod responds
```

### Traefik: What's Running Behind the Scenes

**What is Traefik?**
- Reverse proxy and ingress controller
- Built into K3s (no installation needed!)
- Watches Ingress resources
- Routes traffic based on rules

**Why Traefik with K3s?**
- Simple, built-in
- Supports host-based routing
- Low overhead
- Perfect for learning

**Professional context:** Other ingress controllers: Nginx, Istio, Kong. They all do similar things with different trade-offs.

### Running Part 2

```bash
cd p2

# Create the VM
vagrant up

# This time:
# - Single VM (simpler)
# - More memory (4GB for apps)
# - VirtualBox 7 fixes for nested virt

# SSH and deploy
vagrant ssh macauchyS

# Inside VM:
export KUBECONFIG=/vagrant/k3s.yaml

# Apply application manifests
kubectl apply -f /vagrant/confs/apps.yaml

# Apply ingress rules
kubectl apply -f /vagrant/confs/ingress.yaml

# Verify everything
kubectl get deployments
kubectl get services
kubectl get ingress

# Test from host:
# Option 1: Edit /etc/hosts
sudo bash -c 'echo "192.168.56.110 app1.com app2.com" >> /etc/hosts'

# Then:
curl http://app1.com
# Response: "Hello from App One"

curl http://app2.com
# Response: "Hello from App Two"

curl http://192.168.56.110
# Response: "Hello from App Three" (default route)

# Option 2: Use curl Host header (no /etc/hosts edit)
curl -H "Host: app1.com" http://192.168.56.110
```

### Understanding Scaling

**Replicas in Action:**

```yaml
kind: Deployment
metadata:
  name: app-two
spec:
  replicas: 3  # ← Run 3 copies
```

```bash
# Check pods
kubectl get pods -l app=app-two

# Output:
# NAME           READY   STATUS    RESTARTS   AGE
# app-two-aaa    1/1     Running   0          10s
# app-two-bbb    1/1     Running   0          10s
# app-two-ccc    1/1     Running   0          10s

# Service load-balances across all three
for i in {1..6}; do
  curl -H "Host: app2.com" http://192.168.56.110
done
# Responses come from different pods
# K8s distributes traffic

# Kill a pod
kubectl delete pod app-two-aaa

# K8s immediately creates replacement
kubectl get pods -l app=app-two
# Still 3 pods!
# This is self-healing

# Scale up to 5
kubectl scale deployment app-two --replicas=5
kubectl get pods -l app=app-two
# Now 5 running!

# Scale down to 2
kubectl scale deployment app-two --replicas=2
# K8s terminates 3 pods gracefully
```

### What You've Learned in Part 2

**Deployments:**
- Manage multiple pod copies
- Self-healing (restart on crash)
- Scalable (add/remove replicas)
- Rolling updates (deploy new versions)

**Services:**
- Stable endpoints for pods
- Load-balancing across replicas
- Service discovery via DNS

**Ingress:**
- External traffic routing
- Hostname-based routing (app1.com vs app2.com)
- L7 (application layer) routing

**Traefik:**
- Ingress controller built into K3s
- Watches Ingress resources
- Dynamically updates routing

---

## Part 3: GitOps with Argo CD

### The Reality of Manual Deployments

**Current workflow (without GitOps):**

```bash
# I want to update app to v2
vim deployment.yaml
# Change: image: app:v1 → v2

# Now apply manually
kubectl apply -f deployment.yaml

# Questions that arise:
# - What changed? (no history)
# - Who changed it? (not tracked)
# - When? (no audit trail)
# - Why? (no commit message)
# - How do I rollback? (no easy way)
# - What if two people edit simultaneously? (merge conflict)
# - How does this sync with dev, staging, prod? (manual work)
```

**Problems:**
- Not version-controlled
- Not auditable
- Error-prone (typos deploy to production)
- Doesn't scale (manual per environment)
- Hard to rollback (what was the previous version?)

### What is GitOps?

**Core Principle:** Git is the single source of truth for desired state.

```
You commit to Git
    ↓
GitOps controller detects change
    ↓
Controller applies manifests to cluster
    ↓
Cluster converges to desired state
    ↓
Everything is auditable via Git
```

**Key Benefits:**
- **Version control:** Every change in Git
- **Auditability:** Who changed what when why
- **Rollback:** `git revert` to previous state
- **Reproducibility:** Git state = cluster state always
- **Review process:** Pull requests before deployment
- **Automation:** No manual kubectl apply

### Argo CD: Implementing GitOps

**What is Argo CD?**
- A Kubernetes controller that implements GitOps
- Watches Git repository
- Automatically applies manifests to cluster
- Ensures cluster matches Git state

**Why Argo CD?**
- Purpose-built for GitOps
- Excellent UI/API
- Integrates with GitHub/GitLab
- Handles complex deployments
- Industry standard

**Architecture:**

```
┌─────────────────────────────────┐
│   GitHub Repository             │
│   (p3/confs/)                   │
│   - deployment.yaml             │
│   - service.yaml                │
│   - kustomization.yaml          │
└──────────────┬──────────────────┘
               │ (watches)
               ↓
┌─────────────────────────────────┐
│   Argo CD (argocd namespace)    │
│                                 │
│  argocd-repo-server:            │
│  - Clones GitHub repo           │
│  - Parses YAML                  │
│  - Detects changes              │
│                                 │
│  argocd-application-controller: │
│  - Watches Application CRD      │
│  - Applies manifests            │
│  - Syncs cluster to Git         │
│                                 │
│  argocd-server:                 │
│  - Web UI/API                   │
│  - Shows sync status            │
└──────────────┬──────────────────┘
               │ (applies to)
               ↓
┌─────────────────────────────────┐
│   K3d Cluster                   │
│   (dev namespace)               │
│                                 │
│   Deployment:                   │
│   - 1 pod running app           │
│   - Image matches Git           │
│   - Replicas match Git          │
└─────────────────────────────────┘
```

### K3d: Why We Switch to Docker

**Part 1-2: Vagrant + VirtualBox**
```
Your computer
  ↓
VirtualBox software
  ↓
Full Linux VM (boots like real computer)
  ↓
K3s running in VM
  ↓
Your containers
```

**Complexity:** High (multiple abstraction layers)
**Speed:** 3-5 minutes to boot
**Resource use:** High (full OS per VM)

**Part 3: K3d**
```
Your computer
  ↓
Docker
  ↓
K3s container (lightweight)
  ↓
Your containers
```

**Complexity:** Low (one abstraction layer)
**Speed:** 10-30 seconds to boot
**Resource use:** Low (shares host OS)

**Why the switch?**
- Part 3 focuses on GitOps (automation), not infrastructure
- K3d is faster for development (iterate quicker)
- Less resource usage (laptop battery life)
- Same K3s, same kubectl commands

### Installing K3d

**What K3d Does:**
- Downloads K3s container image
- Creates Docker containers (server + agents)
- Sets up Docker networking
- Configures kubeconfig

**Installation:**
```bash
# Download and install K3d binary
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Verify
k3d version
# Output: k3d version v5.8.3

# Create a cluster
k3d cluster create macauchy \
  --servers 1 \
  --agents 2 \
  --port "80:80@loadbalancer" \
  --port "443:443@loadbalancer" \
  --wait

# What this does:
# - 1 control plane server
# - 2 worker agents
# - Expose port 80 (HTTP)
# - Expose port 443 (HTTPS)
# - Wait for nodes to be ready

# Verify
kubectl get nodes

# Should show:
# k3d-macauchy-server-0   Ready   control-plane
# k3d-macauchy-agent-0    Ready   <none>
# k3d-macauchy-agent-1    Ready   <none>
```

### Argo CD Installation

**What Gets Installed:**
- Custom Resource Definitions (Application, ApplicationSet)
- Service accounts and RBAC
- Controllers (application-controller, repo-server)
- Web UI (argocd-server)
- Cache/storage (redis)
- Supporting services

```bash
# Create namespace for Argo CD
kubectl create namespace argocd

# Apply official Argo CD manifests
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Verify
kubectl get pods -n argocd

# Shows all Argo CD components running
```

### The Application CRD: Core of GitOps

**What is a CRD?**
- Custom Resource Definition
- Extends Kubernetes with new resource types
- Argo CD defines "Application" CRD

**Application Resource:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: macauchy-app
  namespace: argocd
spec:
  # Where to get manifests (Git source)
  source:
    repoURL: https://github.com/maxime-c16/inception_of_things.git
    # Which Git repo to watch

    targetRevision: HEAD
    # Which branch (HEAD = main branch)

    path: p3/confs
    # Which directory contains manifests

  # Where to deploy (Kubernetes destination)
  destination:
    server: https://kubernetes.default.svc
    # This cluster (internal address)

    namespace: dev
    # Deploy to 'dev' namespace

  # How to sync
  syncPolicy:
    automated:
      prune: true
      # Delete K8s objects if removed from Git

      selfHeal: true
      # Revert manual changes, always match Git

    syncOptions:
    - CreateNamespace=true
    # Create namespace if it doesn't exist
```

### Understanding Sync Policy

**`prune: true`**
```
Git has:     deployment.yaml
Cluster has: deployment.yaml, service.yaml

Result: K8s deletes service.yaml
Why:     If it's not in Git, it shouldn't exist in cluster
```

**`selfHeal: true`**
```
Git says: replicas: 3
Someone runs: kubectl scale deployment app --replicas=1

Argo CD detects mismatch
Argo CD corrects: replicas back to 3

Why: Git is the source of truth, drift isn't allowed
```

**`CreateNamespace=true`**
```
Git manifest targets 'dev' namespace
But 'dev' namespace doesn't exist

Result: Argo CD creates the namespace automatically
Why:    Reduces manual setup
```

### The GitOps Workflow

**Step 1: Update Your Manifest**
```yaml
# p3/confs/deployment.yaml
containers:
- name: app
  image: wil42/playground:v1  # ← Current

# Change to:
  image: wil42/playground:v2  # ← Updated
```

**Step 2: Commit and Push to Git**
```bash
git add p3/confs/deployment.yaml
git commit -m "chore(p3): update app to v2"
git push origin main

# Commit message should explain WHY
# Git history becomes operational history
```

**Step 3: Argo CD Detects Change**
```
GitHub receives your push
Argo CD polls GitHub (or receives webhook)
Argo CD detects: deployment.yaml changed
Argo CD fetches new manifest
Argo CD compares to cluster state
Argo CD detects: image changed from v1 to v2
```

**Step 4: Automatic Sync**
```
Argo CD applies new manifest
Kubernetes:
  1. Detects image change
  2. Creates new ReplicaSet with v2 image
  3. Starts new pods with v2
  4. Waits for them to be ready
  5. Terminates old pods with v1
  (This is a rolling update - no downtime!)
```

**Step 5: Verify in Argo CD UI**
```bash
# Port forward to Argo CD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open: https://localhost:8080
# Login: admin / <password from earlier>
# See: macauchy-app synchronized
# Shows: deployment, service, pods all in sync
```

### Testing GitOps: The Real Magic

```bash
# Terminal 1: Watch Argo CD Application
kubectl get application macauchy-app -n argocd -w

# Terminal 2: Watch pods
kubectl get pods -n dev -w

# Terminal 3: Make the change
# Edit deployment.yaml: v1 → v2
git add . && git commit -m "update to v2" && git push

# Watch Terminal 1:
# SYNC STATUS changes: Synced → OutOfSync → Synced
# HEALTH: Progressing → Healthy

# Watch Terminal 2:
# Old pod terminates
# New pod appears with v2 image

# Verify the app works:
curl http://<service-ip>:8888/
# Response: {"status":"ok", "message": "v2"}
```

This is the magic moment. You made a change in Git, pushed to GitHub, and the cluster automatically updated itself. No `kubectl apply`, no scripts, no manual work.

### Advantages of GitOps

**Compare: Traditional Deployment**
```bash
# Manual approach
kubectl set image deployment/app app=image:v2
# - Not tracked in Git
# - No audit trail
# - Hard to reproduce
# - Can't code review
# - Rollback is pain
```

**Compare: GitOps Deployment**
```bash
# Git approach
git commit -m "update app to v2"
git push
# - Tracked in Git
# - Full audit trail (when, who, why)
# - Reproducible (git checkout old-commit)
# - Code review possible (pull request)
# - Rollback is: git revert
```

---

## Common Pitfalls & Solutions

### Network & Infrastructure Issues

**Issue: VMs can't reach each other (Part 1)**

```bash
# Diagnose
vagrant ssh macauchyS
ping 192.168.56.111  # Try to reach worker

# If fails:
# Check network exists
ip addr show

# Should show a private network interface (eth1, enp0s8, etc.) with 192.168.56.110

# If private network interface doesn't appear:
exit
vagrant reload  # Reboot VM and reconfigure networking

# Our setup scripts automatically detect the interface name, so it works
# with eth1, enp0s8, or other predictable naming schemes
```

**Issue: K3s binds to wrong interface**

```bash
# Symptom: Worker can't reach server at 192.168.56.110

# Cause: K3s bound to wrong network interface (e.g., localhost)

# Solution: Use --node-ip flag
INSTALL_K3S_EXEC="--node-ip=192.168.56.110" sh -
```

### Kubernetes Issues

**Issue: "ImagePullBackOff"**

```bash
# Symptom:
kubectl get pods
# Status: ImagePullBackOff

# This means: Can't pull the image

# Diagnose:
kubectl describe pod <pod-name>
# Events section shows actual error

# Common causes and fixes:

# 1. Image doesn't exist
#    Solution: Check spelling
#    docker search hashicorp/http-echo

# 2. Image is private (needs credentials)
#    Solution: Create imagePullSecrets

# 3. Docker registry is down
#    Solution: Wait or use different registry
```

**Issue: "CrashLoopBackOff"**

```bash
# Symptom: Pod starts but crashes immediately

# Diagnose:
kubectl logs <pod-name>
# Shows why the app crashed

# Common causes:
# 1. App doesn't accept arguments
# 2. App can't find config files
# 3. Port is already in use
# 4. App has bugs

# Fix:
# - Check app documentation
# - Verify arguments are correct
# - Check config file paths
```

**Issue: Pod stuck in "Pending"**

```bash
# Symptom: Pod won't start

# Diagnose:
kubectl describe pod <pod-name>
# Events section shows why

# Common causes:
# 1. Not enough resources
#    kubectl describe nodes  # Check available resources
#    kubectl set resources deployment <name> --limits=memory=512Mi
#
# 2. PersistentVolumeClaim doesn't exist
#    kubectl get pvc
#
# 3. Node selector can't match
#    kubectl get nodes --show-labels
#
# 4. Network policy blocking
#    kubectl get networkpolicy
```

### Git & GitHub Issues

**Issue: Authentication fails when pushing**

```bash
# Error: "Authentication failed"

# Solution 1: Use HTTPS with personal access token
git remote set-url origin https://github.com/username/repo.git
# macOS: Credentials stored in Keychain
# Linux: Use credential manager or token

# Solution 2: Use SSH
ssh-keygen -t ed25519 -C "your-email@example.com"
# Add public key to GitHub Settings → SSH Keys
git remote set-url origin git@github.com:username/repo.git
```

**Issue: Argo CD can't access private GitHub repo**

```bash
# Argo CD works with public repos by default
# For private repos, create credentials secret:

kubectl create secret generic gh-credentials \
  --from-literal=username=your-username \
  --from-literal=password=your-token \
  -n argocd

# Then reference in Application:
source:
  repoURL: https://github.com/username/private-repo.git
  username: your-username
  password: your-token
```

---

## Reflections & Key Learnings

### The Progression of Understanding

**Day 1: Confusion**
```bash
vagrant up
# Magical things happen
# VMs appear
# Kubernetes is running
# But... what just happened?
```

**Day 2: "Oh, services are endpoints"**
```yaml
kind: Service
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 8080
```

"So service is a load balancer that finds pods with matching labels? That makes sense!"

But then: "Why do I need both Deployment AND Service?"

This is when you realize: Kubernetes isn't designed for simplicity, it's designed for correctness. The separation is intentional.

**Day 3: "Git is the source of truth"**

```bash
git push
# ... and the cluster automatically updates!
```

"Wait, I didn't run kubectl once. The system updated itself from Git!"

That's when it clicked. You're not managing infrastructure anymore—you're declaring desired state in Git, and controllers ensure it's achieved.

**Day 4: Full Understanding**

The entire system makes sense:
- Vagrant/VMs provide compute resources
- Kubernetes orchestrates containers on those resources
- Services provide networking
- Ingress provides external access
- Argo CD automates deployments from Git

Each layer does one job well.

### What This Teaches Beyond Specific Technologies

This isn't really about Vagrant, K3s, or Argo CD. Those are tools.

The real lessons:

**1. Infrastructure as Code**
- Describe your systems in code
- Version control them
- Automate their creation
- Result: Reproducible, documented, auditable systems

**2. Declarative Configuration**
- Say "what you want" not "how to achieve it"
- Kubernetes: "I want 5 replicas" (K8s figures out how)
- Terraform: "I want this AWS infrastructure" (Terraform figures out how)
- Git as GitOps: "I want this state" (Controllers figure out how)

**3. Automation Scales Better Than Humans**
- First app: manual kubectl commands are fine
- 10 apps: Still manageable
- 100 apps: Impossible manually, trivial with automation
- 1000 apps: Requires automation

Argo CD means 1000 apps = same effort as 1 app (just bigger Git repo)

**4. Self-Healing Systems**
- Don't build fragile systems
- Build systems that detect and fix problems
- Kubernetes does this (restartscrashed pods)
- Argo CD does this (fixes drift from Git)
- Production systems require this

**5. Auditability is Security**
- Every change tracked in Git
- Git blame shows who changed what when why
- Rollback to previous state
- Security audits are simple (just check Git)

### The Aha Moment

Mine was when I:
1. Changed the image tag in deployment.yaml
2. Committed to Git
3. Watched Argo CD automatically deploy it
4. Tested the new version and it worked

No SSH, no manual kubectl apply, no scripts. Just Git + automation.

That's when I understood why modern DevOps exists. It's not to make things complicated—it's to make deployments boring and reliable.

---

## Going Deeper

### Concepts for Advanced Study

**Persistent Storage**
Your apps need data that survives pod crashes:

```yaml
kind: PersistentVolumeClaim
metadata:
  name: database-data
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 10Gi
---
kind: Deployment
spec:
  template:
    spec:
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: database-data
      containers:
      - name: db
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql
```

**StatefulSets**
For applications that need persistent identity (databases, caches):

```yaml
kind: StatefulSet  # Instead of Deployment
metadata:
  name: postgres
spec:
  replicas: 3
  # Unlike Deployment, creates: postgres-0, postgres-1, postgres-2
  # Stable network identity: postgres-0.postgres.default.svc.cluster.local
  # Persistent storage per replica
  # Ordered creation/deletion
```

**Resource Limits**
Tell Kubernetes how much resources your app needs:

```yaml
containers:
- name: app
  resources:
    requests:
      memory: "256Mi"    # "I need at least 256MB"
      cpu: "250m"        # "I need at least 0.25 cores"
    limits:
      memory: "512Mi"    # "Kill me if I use more than 512MB"
      cpu: "500m"        # "Throttle me if I use more than 0.5 cores"
```

**Health Checks**
Tell Kubernetes how to verify your app is healthy:

```yaml
containers:
- name: app
  livenessProbe:
    httpGet:
      path: /health
      port: 8080
    initialDelaySeconds: 30
    periodSeconds: 10
    # If /health fails, restart pod

  readinessProbe:
    httpGet:
      path: /ready
      port: 8080
    initialDelaySeconds: 5
    periodSeconds: 5
    # If /ready fails, remove from load balancer but don't restart
```

**Network Policies**
Control traffic between pods:

```yaml
kind: NetworkPolicy
metadata:
  name: allow-from-app
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 5432
  # Only pods with label "app: backend" can reach database
```

### Advanced Deployment Patterns

**Blue-Green Deployments**
```bash
# Run v1 (blue) in production
# Deploy v2 (green) alongside
kubectl apply -f deployment-v2.yaml

# Test v2
kubectl port-forward svc/my-app-v2 :8080

# If good, switch traffic:
kubectl patch service my-app -p '{"spec":{"selector":{"version":"v2"}}}'

# If bad, switch back instantly:
kubectl patch service my-app -p '{"spec":{"selector":{"version":"v1"}}}'

# No downtime, instant rollback
```

**Canary Deployments**
```yaml
# Use Flagger (a controller) to gradually route traffic
# 10% → v2 (monitor error rate)
# 25% → v2 (if good, increase)
# 50% → v2
# 100% → v2

# If error rate spikes at any point: automatic rollback
```

**Multi-Environment GitOps**

```
github.com/company/infrastructure
  ├── clusters/
  │   ├── dev/
  │   │   ├── namespace-dev.yaml
  │   │   └── apps.yaml (replicas: 1, no resources)
  │   ├── staging/
  │   │   ├── namespace-staging.yaml
  │   │   └── apps.yaml (replicas: 2, medium resources)
  │   └── prod/
  │       ├── namespace-prod.yaml
  │       └── apps.yaml (replicas: 5, high resources)
  │
  └── Argo CD Applications:
      ├── dev-app → watches dev/
      ├── staging-app → watches staging/
      └── prod-app → watches prod/

# Each environment has its own Argo CD Application
# Each watches different directory
# Changes propagate: dev → staging → prod (as you promote)
```

---

## Practical Command Reference

### Vagrant Commands

```bash
# Lifecycle
vagrant up                    # Create and start VMs
vagrant ssh <vm-name>       # SSH into VM
vagrant halt                # Stop VMs (keep disk)
vagrant destroy -f          # Delete VMs completely
vagrant reload              # Reboot and re-provision
vagrant reload --provision  # Force re-run provisioning scripts

# Status
vagrant status              # Check all VMs
vagrant validate            # Check Vagrantfile syntax
vagrant global-status       # All VMs across all directories
```

### Kubernetes Commands (kubectl)

```bash
# Cluster Info
kubectl cluster-info                # Cluster address
kubectl get nodes                   # List nodes
kubectl describe node <name>        # Detailed node info

# Deployments
kubectl get deployments             # List
kubectl describe deployment <name>  # Details
kubectl logs deployment/<name>      # Logs
kubectl scale deployment <name> --replicas=3  # Scale
kubectl set image deployment/<name> app=image:v2  # Update image
kubectl rollout status deployment/<name>       # Watch update
kubectl rollout restart deployment/<name>      # Restart pods
kubectl rollout history deployment/<name>      # Version history
kubectl rollout undo deployment/<name>         # Rollback

# Pods
kubectl get pods                    # List
kubectl get pods -A                 # All namespaces
kubectl describe pod <name>         # Details
kubectl logs <pod-name>             # Logs
kubectl logs <pod-name> --previous  # Previous container logs
kubectl exec -it <pod> -- bash      # Shell into pod
kubectl port-forward pod/<name> 8080:8080  # Port forward
kubectl delete pod <name>           # Delete (will respawn if in deployment)

# Services & Ingress
kubectl get svc                     # List services
kubectl get ingress                 # List ingress
kubectl describe ingress <name>     # Ingress details

# Configuration
kubectl get configmap               # List
kubectl describe configmap <name>   # Details
kubectl get secret                  # List
kubectl get secret <name> -o yaml   # View secret (base64 encoded)

# Debugging
kubectl get events                  # Recent cluster events
kubectl describe pod <pod>          # Shows events explaining issues
kubectl logs --tail=50 <pod>        # Last 50 lines
kubectl debug pod/<pod> -it --image=busybox  # Debug container

# YAML Operations
kubectl apply -f deployment.yaml               # Create/update
kubectl apply -f ./directory/                  # All files in directory
kubectl apply --dry-run=client -f deployment.yaml  # Preview changes
kubectl diff -f deployment.yaml                # Show differences
kubectl delete -f deployment.yaml              # Remove
kubectl edit deployment <name>                 # Edit in editor
kubectl patch deployment <name> -p '{"spec":{"replicas":3}}'  # Patch
```

### K3d Commands

```bash
# Cluster Management
k3d cluster create <name>           # Create cluster
k3d cluster list                    # List clusters
k3d cluster delete <name>           # Delete cluster
k3d cluster start <name>            # Start stopped cluster
k3d cluster stop <name>             # Stop cluster

# Node Management
k3d node create --cluster=<cluster> # Add node
k3d node list -c <cluster>          # List nodes in cluster

# Docker Integration
k3d image import <image> -c <cluster>  # Import image into cluster
```

### Argo CD Commands

```bash
# Access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get Credentials
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo

# List Applications
kubectl get application -n argocd
kubectl get application -n argocd -o wide

# Get Status
kubectl describe application <name> -n argocd
kubectl get application <name> -n argocd -o jsonpath='{.status.sync.status}'

# Trigger Sync
kubectl patch application <name> -n argocd \
  --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'

# View Logs
kubectl logs -n argocd deployment/argocd-application-controller
kubectl logs -n argocd deployment/argocd-repo-server
kubectl logs -n argocd deployment/argocd-server
```

### Git Commands

```bash
# Setup
git config user.name "Your Name"
git config user.email "you@example.com"
git clone <url>                     # Clone repository

# Everyday
git status                          # See changes
git add <file>                      # Stage changes
git add .                           # Stage all
git commit -m "message"             # Commit with message
git push origin <branch>            # Push to remote

# Branching
git branch                          # List branches
git branch <name>                   # Create branch
git checkout <name>                 # Switch branch
git checkout -b <name>              # Create and switch

# History
git log --oneline                   # Recent commits
git log -p                          # With changes
git show <commit>                   # Show commit details

# Undo
git restore <file>                  # Undo local changes
git restore .                       # Undo all local changes
git revert <commit>                 # Create undo commit (safe)
git reset --hard <commit>           # Discard commits (danger!)

# Diff
git diff                            # Unstaged changes
git diff --staged                   # Staged changes
git diff <branch>                   # Compare branches
```

---

## Conclusion: From Infrastructure Complexity to Simple Abstractions

### The Journey Mapped

When I started, I saw three separate parts. By the end, I understood they tell one coherent story:

**Part 1: Foundation**
- Build VMs (Vagrant abstracts VM complexity)
- Configure networking (private network enables communication)
- Install K3s (K3s abstracts Kubernetes complexity)
- Demonstrate clustering (multiple machines working together)

**Part 2: Application Deployment**
- Deploy apps (Deployments manage containers)
- Expose services (Services provide stable endpoints)
- Route traffic (Ingress routes external traffic)
- Demonstrate orchestration (K8s manages app lifecycle)

**Part 3: Automation**
- Store configs in Git (version control and auditability)
- Automate deployments (Argo CD watches Git and syncs)
- Achieve GitOps (Git becomes source of truth)
- Demonstrate reliability (self-healing, easy rollback)

### Why Each Abstraction Layer Matters

**Vagrant**
- Without Vagrant, infrastructure is manual (time-consuming, error-prone)
- With Vagrant, infrastructure is code (reproducible, documented, testable)

**Kubernetes**
- Without K8s, you manage containers manually (impossible at scale)
- With K8s, containers self-orchestrate (scaling, healing, updates)

**Argo CD**
- Without GitOps, deployments are imperative (undocumented, unauditable)
- With GitOps, deployments are declarative (documented, auditable, reversible)

Each layer removes complexity from the level above.

### The Real Value

The specific tools (Vagrant, K3s, Argo CD) matter less than the principles they demonstrate:

1. **Infrastructure as Code** - Systems described in files, not clicked in GUIs
2. **Declarative Configuration** - Describe desired state, let controllers achieve it
3. **Automation at Scale** - Manage 1 app or 1000 apps with same complexity
4. **Self-Healing Systems** - Systems detect and fix problems automatically
5. **Auditability** - Everything tracked, reversible, understandable

These principles apply everywhere:
- Use Terraform instead of Vagrant? Same principles
- Use AWS ECS instead of Kubernetes? Same principles
- Use Flux instead of Argo CD? Same principles

### The Aha Moment (Mine Was...)

Watching my commit automatically deploy to production. No scripts, no manual steps, just Git + automation.

That's when I understood: **The goal of infrastructure is not to be clever or impressive. It's to be boring and reliable.**

Boring means:
- Deployments work the same way every time
- Failures are detected and fixed automatically
- Changes are tracked and reversible
- New team members can understand the system
- You can deploy with confidence at 3 AM

### Why This Matters for Your Career

Understanding these principles:
- Makes you valuable (this is what companies pay for)
- Makes you confident (you understand complex systems)
- Makes you productive (automation does work for you)
- Makes you adaptable (principles apply to any stack)

Companies aren't looking for experts in Kubernetes 1.31.5. They're looking for people who understand:
- How to describe infrastructure as code
- How to automate deployments
- How to build self-healing systems
- How to make changes safely and reversibly

This project teaches those.

---

## Final Thoughts

Six months ago, I thought this was a homework project. Now I see it's a foundation for understanding modern infrastructure.

The infrastructure landscape changes constantly:
- Kubernetes 1.30 → 1.31 → 1.32
- Argo CD gets new features
- New tools emerge (more automation, better observability)

But the principles are eternal:
- Code drives operations
- Automation scales better than humans
- Version control enables safety
- Self-healing creates reliability
- Declarative configuration beats imperative

Master the principles, understand any new tool.

You've built:
- ✅ A reproducible multi-node cluster
- ✅ Applications running on Kubernetes
- ✅ An automated deployment pipeline
- ✅ Understanding of modern DevOps

The infrastructure journey doesn't end here. It's just beginning.

What comes next:
- **Observability:** Prometheus + Grafana (see what's happening)
- **Secrets Management:** Vault or Sealed Secrets (secure credentials)
- **Service Mesh:** Istio or Linkerd (advanced networking)
- **Cost Optimization:** Rightsizing, node consolidation
- **Disaster Recovery:** Backups, multi-region failover
- **Security:** RBAC, network policies, admission controllers

But you have the foundation. Everything else builds on principles you've now learned.

---

## Appendix: Quick Reference Checklists

### Part 1 Checklist

- [ ] Vagrant and VirtualBox installed
- [ ] Vagrantfile created with two VMs
- [ ] Server setup script written (installs K3s)
- [ ] Worker setup script written (joins cluster)
- [ ] `vagrant up` succeeds
- [ ] `kubectl get nodes` shows 2 nodes, both Ready
- [ ] kubeconfig extracted and saved
- [ ] Can access cluster from host machine

### Part 2 Checklist

- [ ] Part 2 Vagrantfile created (single VM)
- [ ] Deployment manifests created (3 apps)
- [ ] Service manifests created (3 services)
- [ ] Ingress manifest created
- [ ] `vagrant up` succeeds
- [ ] Applications deployed: `kubectl apply -f confs/apps.yaml`
- [ ] Ingress deployed: `kubectl apply -f confs/ingress.yaml`
- [ ] Can access apps via hostname
- [ ] Can scale deployments
- [ ] Self-healing works (pod restart, replica restoration)

### Part 3 Checklist

- [ ] Docker installed
- [ ] K3d installed
- [ ] K3d cluster created with `k3d cluster create macauchy`
- [ ] Argo CD installed: `kubectl apply -n argocd -f manifest`
- [ ] GitHub repository is public
- [ ] Manifests in p3/confs/ pushed to GitHub
- [ ] Argo CD Application created and synced
- [ ] Application deployed and accessible
- [ ] Test GitOps: change v1 → v2 in Git
- [ ] Automatic sync confirmed (Argo CD syncs change)
- [ ] Application v2 verified working

---

**You've completed the entire journey. Congratulations.** 🎉

The infrastructure world is now yours to build upon.

