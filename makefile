# Default target
.DEFAULT_GOAL := help

COMPOSE_FILE := compose.yaml
K3S_MASTER_IP := 192.168.4.10



.PHONY: help
help: ## Show help for each target
	@echo "Usage: make [target]"
	@echo
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?##"} {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

.PHONY: up
up: ## Bring up the containers using podman-compose
	sudo podman-compose -f $(COMPOSE_FILE) up -d

.PHONY: down
down: ## Tear down the containers using podman-compose
	sudo podman-compose -f $(COMPOSE_FILE) down -v

.PHONY: clean
clean: ## Remove volume data for a fresh start
	@echo "🧹 Cleaning up named Podman volumes..."
	@rm -rf ./kubeconfig.yaml
	@rm -rf ~/.kube/config
	@rm -rf ./kubeconfig.yaml.bak


.PHONY: replace-kubeconfig
replace-kubeconfig: ## Modify kubeconfig.yaml, then copy to ~/.kube/config
	@echo "🛠  Rewriting server endpoint in kubeconfig.yaml to point to $(K3S_MASTER_IP)..."
	sed -i 's|https://127.0.0.1:6443|https://$(K3S_MASTER_IP):6443|g' ./kubeconfig.yaml

	@echo "🔁 Copying modified kubeconfig.yaml to ~/.kube/config..."
	mkdir -p $$HOME/.kube
	cp -v ./kubeconfig.yaml $$HOME/.kube/config
	chmod 600 $$HOME/.kube/config



.PHONY: setup-host-macvlan
setup-host-macvlan: ## Create a macvlan peer interface on host for 192.168.4.0/24
	@echo "🔧 Creating macvlan interface 'mac0' on host (192.168.4.1/24)..."
	sudo ip link delete mac0 2>/dev/null || true
	sudo ip link add mac0 link eth0 type macvlan mode bridge
	sudo ip addr add 192.168.4.1/24 dev mac0
	sudo ip link set mac0 up
	@echo "✅ mac0 is up at 192.168.4.1"



.PHONY: cleanup-host-macvlan
cleanup-host-macvlan: ## Remove the macvlan peer interface 'mac0' from host
	@echo "🧹 Removing macvlan interface 'mac0' from host..."
	sudo ip link delete mac0 2>/dev/null || echo "⚠️  mac0 does not exist"
	@echo "✅ mac0 cleaned up"
