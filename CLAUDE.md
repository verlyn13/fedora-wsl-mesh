# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository manages a Fedora WSL2 node participating in a distributed mesh network via Tailscale VPN. It serves as a bridge between Windows/WSL environments and Linux-based mesh nodes, running on Windows 11 within the University of Alaska network.

## Key Commands

### Daily Operations
- `make status` - Full system and mesh network health check
- `make check-mesh` - Test connectivity to mesh peers
- `make diagnose` - Run comprehensive diagnostics
- `make mesh-user-status` - Check mesh-ops user status
- `make mesh-user-switch` - Switch to mesh-ops user

### Network Management
- `make mesh-start` - Start Tailscale connection
- `make mesh-stop` - Stop Tailscale connection  
- `make reset-network` - Reset WSL network stack (use when connectivity issues occur)
- `tailscale status` - Check Tailscale connection status
- `tailscale ping <hostname>` - Test connectivity to specific mesh nodes

### Troubleshooting
- `./scripts/health/check-mesh-health.sh` - Detailed health check with color output
- `./scripts/maintenance/wsl-network-reset.sh` - Reset WSL network when DNS/connectivity fails
- `journalctl -u tailscaled -n 50` - Check Tailscale service logs

### Maintenance
- `make update` - Update system packages
- `make backup` - Create configuration backup
- `make sync-upstream` - Sync with mesh-infra repository

## Architecture Overview

### Network Topology
This WSL node connects to a mesh network with:
- **hetzner-hq** (100.84.151.58) - Primary cloud server node
- **laptop-hq** (100.84.2.8) - Development laptop node
- **wsl-fedora-kbc** (100.88.131.44) - This node

### Critical Configuration Files
- `config/network/wsl-network.conf` - Central configuration with node identity, IPs, and settings
- `config/tailscale/tailscale-up.sh` - Tailscale connection script (uses --reset flag to avoid conflicts)
- `scripts/health/check-mesh-health.sh` - Health monitoring using Tailscale IPs for peer checks

### WSL-Specific Considerations
1. **Dynamic IP Assignment**: WSL IP changes on restart - scripts use 0.0.0.0 bindings
2. **NAT Networking**: No direct inbound connections - requires Windows firewall rules
3. **MTU Optimization**: Set to 1280 for stability (see config files)
4. **DNS Resolution**: Can fail after sleep - use `make reset-network` to fix

### Integration Points
- Related repositories at `../mesh-infra`, `../hetzner`, `../fedora-top-mesh`
- State synchronization via `state/` directory
- Windows integration through `/mnt/c` and WSL interop

## Current State

- **Phase 2.8**: Complete (mesh-ops user deployed)
- **Tailscale**: v1.86.2 connected (IP: 100.88.131.44)
- **mesh-ops**: Operational (UID/GID 2000)
- **Peer Nodes**: All reachable and Phase 2.8 complete
- **SSH**: Running on port 22 (Hetzner uses port 2222)
- **Security**: Fixed dangerous sudo wildcards

## Common Issues and Solutions

### "Cannot resolve hostnames"
Run `make reset-network` or manually fix with:
```bash
sudo rm /etc/resolv.conf
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
```

### "Tailscale won't start"
```bash
sudo systemctl restart tailscaled
sudo tailscale up --reset --hostname=wsl-fedora-kbc --accept-routes --accept-dns --ssh
```

### "Clock drift after sleep"
```bash
sudo hwclock -s
```

## Development Workflow

1. Always check connectivity first: `make status`
2. When modifying network configs, test with `make check-mesh`
3. Use `make backup` before major changes
4. Scripts in `scripts/` are executable and source config from `config/network/wsl-network.conf`
5. Documentation updates should include STATUS.md for operational state