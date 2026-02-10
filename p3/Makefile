.PHONY: setup cluster argocd deploy verify upgrade clean status help

CLUSTER_NAME := inception
ARGOCD_NS := argocd
DEV_NS := dev
APP_NAME := macauchy-app

help:
	@echo "Part 3 - K3d + Argo CD Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make setup       - Full setup: cluster + Argo CD + application"
	@echo "  make cluster     - Create K3d cluster (idempotent)"
	@echo "  make argocd      - Install Argo CD (idempotent)"
	@echo "  make deploy      - Deploy application via Argo CD (idempotent)"
	@echo "  make verify      - Verify v1 is running"
	@echo "  make upgrade     - Upgrade to v2 and verify"
	@echo "  make status      - Show cluster status"
	@echo "  make clean       - Remove everything"
	@echo "  make help        - Show this message"

# Cluster setup - idempotent
cluster:
	@if k3d cluster list | grep -q $(CLUSTER_NAME); then \
		echo "[✓] K3d cluster '$(CLUSTER_NAME)' already exists"; \
	else \
		echo "[→] Creating K3d cluster..."; \
		bash scripts/setup_k3d.sh; \
	fi

# Argo CD setup - idempotent
argocd: cluster
	@if kubectl get deployment -n $(ARGOCD_NS) argocd-server 2>/dev/null | grep -q argocd-server; then \
		echo "[✓] Argo CD already installed"; \
	else \
		echo "[→] Installing Argo CD..."; \
		bash scripts/setup_argocd.sh; \
	fi
	@echo "[→] Waiting for Argo CD to be ready..."; \
	kubectl rollout status deployment/argocd-server -n $(ARGOCD_NS) --timeout=2m || true

# Application deployment - idempotent
deploy: argocd
	@echo "[→] Deploying application via Argo CD..."
	@kubectl apply -f confs/argocd-app.yaml
	@echo "[→] Waiting for application to deploy..."
	@sleep 5
	@kubectl rollout status deployment/macauchy-app -n $(DEV_NS) --timeout=2m || true

# Verify v1 is running
verify: deploy
	@echo "[→] Verifying v1 is running..."
	@kubectl port-forward svc/$(APP_NAME) -n $(DEV_NS) 8888:8888 > /dev/null 2>&1 &
	@PF_PID=$$!; sleep 2; \
	RESPONSE=$$(curl -s http://localhost:8888/ 2>/dev/null || echo "error"); \
	kill $$PF_PID 2>/dev/null || true; \
	if echo "$$RESPONSE" | grep -q 'v1'; then \
		echo "[✓] v1 is running: $$RESPONSE"; \
	else \
		echo "[✗] v1 not responding properly: $$RESPONSE"; \
		exit 1; \
	fi

# Upgrade to v2
upgrade: deploy
	@echo "[→] Upgrading to v2..."
	@sed -i 's/wil42\/playground:v1/wil42\/playground:v2/g' confs/deployment.yaml
	@echo "[→] Redeploying with v2..."
	@kubectl delete application $(APP_NAME) -n $(ARGOCD_NS) 2>/dev/null || true
	@kubectl apply -f confs/argocd-app.yaml
	@echo "[→] Waiting for v2 deployment..."
	@sleep 8
	@kubectl rollout status deployment/macauchy-app -n $(DEV_NS) --timeout=2m || true
	@echo "[→] Verifying v2 is running..."
	@kubectl port-forward svc/$(APP_NAME) -n $(DEV_NS) 8888:8888 > /dev/null 2>&1 &
	@PF_PID=$$!; sleep 2; \
	RESPONSE=$$(curl -s http://localhost:8888/ 2>/dev/null || echo "error"); \
	kill $$PF_PID 2>/dev/null || true; \
	if echo "$$RESPONSE" | grep -q 'v2'; then \
		echo "[✓] v2 is running: $$RESPONSE"; \
	else \
		echo "[✗] v2 not responding properly: $$RESPONSE"; \
		exit 1; \
	fi
	@git -C . diff confs/deployment.yaml 2>/dev/null || echo "(Git not initialized or no changes detected)"

# Show status
status:
	@echo "=== K3d Cluster Status ==="
	@k3d cluster list | grep $(CLUSTER_NAME) || echo "Cluster not found"
	@echo ""
	@echo "=== Argo CD Status ==="
	@kubectl get deployment -n $(ARGOCD_NS) 2>/dev/null | tail -1 || echo "Argo CD not installed"
	@echo ""
	@echo "=== Application Status ==="
	@kubectl get deployment,pods,svc -n $(DEV_NS) 2>/dev/null || echo "No application deployed"
	@echo ""
	@echo "=== To access Argo CD UI ==="
	@echo "  kubectl port-forward svc/argocd-server -n $(ARGOCD_NS) 8080:443"
	@echo "  https://localhost:8080"
	@echo "  Username: admin"
	@echo "  Password: $$(kubectl -n $(ARGOCD_NS) get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)"

# Full setup
setup: cluster argocd deploy verify
	@echo ""
	@echo "=== Setup Complete ==="
	@echo "Part 3 is ready! Use 'make upgrade' to test the v1→v2 GitOps workflow"

# Cleanup
clean:
	@echo "[→] Cleaning up..."
	@if k3d cluster list | grep -q $(CLUSTER_NAME); then \
		echo "[→] Deleting K3d cluster '$(CLUSTER_NAME)'..."; \
		k3d cluster delete $(CLUSTER_NAME); \
	fi
	@git -C . checkout confs/deployment.yaml 2>/dev/null || echo "(Git checkout skipped)"
	@echo "[✓] Cleanup complete"
