# Makefile for Fedora WSL Mesh Node
# Run 'make help' for available commands

.PHONY: help setup status install-tailscale install-wireguard configure-mesh \
        check-mesh mesh-start mesh-stop reset-network diagnose update sync-upstream \
        clean backup

# Default target
.DEFAULT_GOAL := help

# Colors for output
YELLOW := \033[1;33m
GREEN := \033[0;32m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(GREEN)Fedora WSL Mesh Node - Management Commands$(NC)"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Quick start:"
	@echo "  1. make setup        - Initial system setup"
	@echo "  2. make install-tailscale  - Install Tailscale VPN"
	@echo "  3. make configure-mesh     - Join mesh network"
	@echo "  4. make status            - Check system status"

setup: ## Initial setup of the WSL mesh node
	@echo "$(GREEN)Setting up Fedora WSL Mesh Node...$(NC)"
	@echo "Checking prerequisites..."
	@if [ ! -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then \
		echo "$(RED)Error: Not running in WSL$(NC)"; \
		exit 1; \
	fi
	@echo "✓ WSL environment detected"
	@if [ ! -f /dev/net/tun ]; then \
		echo "$(RED)Error: TUN device not available$(NC)"; \
		exit 1; \
	fi
	@echo "✓ TUN device available"
	@if ! systemctl is-system-running &>/dev/null; then \
		echo "$(YELLOW)Warning: systemd not fully operational$(NC)"; \
	else \
		echo "✓ systemd running"; \
	fi
	@echo ""
	@echo "$(GREEN)Setup complete!$(NC)"
	@echo "Next: Run 'make install-tailscale' or 'make install-wireguard'"

status: ## Show current system and mesh status
	@echo "$(GREEN)System Status Report$(NC)"
	@echo "===================="
	@bash scripts/health/check-mesh-health.sh

install-tailscale: ## Install Tailscale VPN
	@echo "$(GREEN)Installing Tailscale...$(NC)"
	@bash scripts/setup/install-tailscale.sh

install-wireguard: ## Install WireGuard VPN
	@echo "$(GREEN)Installing WireGuard...$(NC)"
	@bash scripts/setup/install-wireguard.sh

configure-mesh: ## Configure and join the mesh network
	@echo "$(GREEN)Configuring Mesh Network...$(NC)"
	@if command -v tailscale &> /dev/null; then \
		echo "Using Tailscale for mesh connection..."; \
		bash config/tailscale/tailscale-up.sh; \
	elif command -v wg &> /dev/null; then \
		echo "Using WireGuard for mesh connection..."; \
		echo "$(YELLOW)Please configure /etc/wireguard/mesh.conf first$(NC)"; \
		echo "Then run: sudo wg-quick up mesh"; \
	else \
		echo "$(RED)No VPN software installed!$(NC)"; \
		echo "Run 'make install-tailscale' or 'make install-wireguard' first"; \
		exit 1; \
	fi

check-mesh: ## Check mesh network connectivity
	@echo "$(GREEN)Checking Mesh Connectivity...$(NC)"
	@bash scripts/health/check-mesh-health.sh | grep -A 20 "Connectivity Tests"

mesh-start: ## Start mesh network services
	@echo "$(GREEN)Starting Mesh Services...$(NC)"
	@if systemctl is-active --quiet tailscaled; then \
		sudo tailscale up; \
		echo "✓ Tailscale started"; \
	fi
	@if [ -f /etc/wireguard/mesh.conf ]; then \
		sudo wg-quick up mesh 2>/dev/null || true; \
		echo "✓ WireGuard started"; \
	fi
	@echo "Mesh services started"

mesh-stop: ## Stop mesh network services
	@echo "$(YELLOW)Stopping Mesh Services...$(NC)"
	@sudo tailscale down 2>/dev/null || true
	@sudo wg-quick down mesh 2>/dev/null || true
	@echo "Mesh services stopped"

reset-network: ## Reset WSL network stack
	@echo "$(YELLOW)Resetting Network Stack...$(NC)"
	@bash scripts/maintenance/wsl-network-reset.sh

diagnose: ## Run full system diagnostics
	@echo "$(GREEN)Running Diagnostics...$(NC)"
	@echo ""
	@echo "=== WSL Information ==="
	@wsl.exe --version | head -1 || echo "WSL version unknown"
	@echo ""
	@echo "=== Network Configuration ==="
	@ip -br addr show
	@echo ""
	@echo "=== DNS Status ==="
	@resolvectl status | head -10
	@echo ""
	@echo "=== Service Status ==="
	@systemctl is-active sshd && echo "✓ SSH: active" || echo "✗ SSH: inactive"
	@systemctl is-active tailscaled 2>/dev/null && echo "✓ Tailscale: active" || echo "○ Tailscale: not installed/inactive"
	@sudo wg show mesh &>/dev/null && echo "✓ WireGuard: active" || echo "○ WireGuard: not configured"
	@echo ""
	@echo "=== Connectivity ==="
	@ping -c 1 -W 2 8.8.8.8 &>/dev/null && echo "✓ Internet: OK" || echo "✗ Internet: Failed"
	@echo ""
	@echo "For detailed diagnostics, run: make status"

update: ## Update system packages
	@echo "$(GREEN)Updating System Packages...$(NC)"
	sudo dnf update -y
	@echo "$(GREEN)Update complete$(NC)"

sync-upstream: ## Sync with mesh-infra repository
	@echo "$(GREEN)Syncing with mesh-infra...$(NC)"
	@if [ -d ../mesh-infra ]; then \
		cd ../mesh-infra && git pull origin main; \
		echo "✓ mesh-infra updated"; \
	else \
		echo "$(YELLOW)mesh-infra repository not found at ../mesh-infra$(NC)"; \
	fi

clean: ## Clean temporary files and logs
	@echo "$(YELLOW)Cleaning temporary files...$(NC)"
	@rm -f *.log *.tmp
	@rm -rf tmp/ temp/
	@sudo journalctl --vacuum-time=7d &>/dev/null
	@echo "✓ Cleanup complete"

backup: ## Create backup of configuration
	@echo "$(GREEN)Creating configuration backup...$(NC)"
	@BACKUP_DIR="backups/$$(date +%Y%m%d_%H%M%S)"; \
	mkdir -p $$BACKUP_DIR; \
	cp -r config/ $$BACKUP_DIR/; \
	cp *.md $$BACKUP_DIR/ 2>/dev/null || true; \
	if [ -f /etc/wireguard/mesh.conf ]; then \
		sudo cp /etc/wireguard/mesh.conf $$BACKUP_DIR/wireguard-mesh.conf; \
	fi; \
	echo "✓ Backup created in $$BACKUP_DIR"

# Advanced targets

firewall-setup: ## Configure Windows firewall for mesh access
	@echo "$(GREEN)Windows Firewall Configuration$(NC)"
	@echo ""
	@echo "Run these commands in elevated PowerShell:"
	@echo ""
	@echo '  # Tailscale'
	@echo '  New-NetFirewallRule -DisplayName "WSL2 Tailscale" \'
	@echo '    -Direction Inbound -Protocol UDP -LocalPort 41641 -Action Allow'
	@echo ""
	@echo '  # WireGuard'
	@echo '  New-NetFirewallRule -DisplayName "WSL2 WireGuard" \'
	@echo '    -Direction Inbound -Protocol UDP -LocalPort 51820 -Action Allow'
	@echo ""
	@echo '  # SSH'
	@echo '  New-NetFirewallRule -DisplayName "WSL2 SSH" \'
	@echo '    -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow'

port-forward: ## Set up Windows port forwarding to WSL
	@echo "$(GREEN)Port Forwarding Setup$(NC)"
	@echo ""
	@echo "WSL IP: $$(hostname -I | cut -d' ' -f1)"
	@echo ""
	@echo "Run in elevated PowerShell to forward ports:"
	@echo '  $$wslIP = "$$(wsl hostname -I | cut -d" " -f1)"'
	@echo '  netsh interface portproxy add v4tov4 listenport=22 listenaddress=0.0.0.0 connectport=22 connectaddress=$$wslIP'

test-mesh: ## Run mesh connectivity tests
	@echo "$(GREEN)Testing Mesh Connectivity...$(NC)"
	@for ip in 10.10.0.1 10.10.0.2 10.10.0.3; do \
		echo -n "Testing $$ip: "; \
		if ping -c 1 -W 2 $$ip &>/dev/null; then \
			echo "$(GREEN)✓ OK$(NC)"; \
		else \
			echo "$(RED)✗ Failed$(NC)"; \
		fi; \
	done

monitor: ## Start real-time monitoring
	@echo "$(GREEN)Starting Network Monitor...$(NC)"
	@echo "Press Ctrl+C to stop"
	@watch -n 2 "ip -br addr show; echo; ss -tunap 2>/dev/null | head -10; echo; tailscale status 2>/dev/null || echo 'Tailscale not running'"

# Git targets

git-init: ## Initialize git repository
	@if [ ! -d .git ]; then \
		git init; \
		git add .; \
		git commit -m "Initial commit: Fedora WSL mesh node configuration"; \
		echo "$(GREEN)Git repository initialized$(NC)"; \
	else \
		echo "$(YELLOW)Git repository already exists$(NC)"; \
	fi

git-status: ## Show git status
	@git status

# Development targets

validate: ## Validate configuration files
	@echo "$(GREEN)Validating configurations...$(NC)"
	@bash -n scripts/**/*.sh && echo "✓ Shell scripts valid" || echo "✗ Shell script errors"
	@if [ -f /etc/wireguard/mesh.conf ]; then \
		sudo wg show mesh &>/dev/null && echo "✓ WireGuard config valid" || echo "✗ WireGuard config invalid"; \
	fi
	@echo "$(GREEN)Validation complete$(NC)"