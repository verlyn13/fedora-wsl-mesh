# Phase 2.8 Preparation: WSL2 Node

## Overview

This document outlines the Phase 2.8 preparation for the fedora-wsl-mesh node, implementing the mesh-ops user architecture as defined in the mesh-infra repository.

## Phase 2.8 Goals

- Create isolated `mesh-ops` user for infrastructure operations
- Establish consistent UID/GID (2000) across all mesh nodes
- Prepare for development tool installation (uv, bun, mise, fish)
- Set up WSL-specific configurations and workarounds
- Enable user-space service management

## WSL-Specific Considerations

### Environment Constraints

1. **No Windows Admin Rights**: Cannot modify Windows firewall or system settings
2. **Corporate Network**: University of Alaska network with restrictions
3. **Dynamic IP Assignment**: WSL IP changes on restart
4. **NAT Networking**: No direct inbound connections
5. **DNS Issues**: Frequent DNS resolution failures after sleep
6. **Clock Drift**: Time synchronization issues after hibernation

### WSL Adaptations

The mesh-ops implementation for WSL2 includes specific adaptations:

- No Docker group (will use rootless Podman instead)
- Limited sudo permissions appropriate for WSL environment
- DNS and clock fix functions in user profile
- Windows interop path configuration
- WSL-aware network reset capabilities

## Implementation Status

### Created Scripts

1. **`scripts/setup/create-mesh-ops-user.sh`**
   - Creates mesh-ops user with UID/GID 2000
   - Sets up WSL-specific sudo rules
   - Creates directory structure
   - Configures bash profile with WSL fixes

2. **`scripts/setup/validate-mesh-ops.sh`**
   - Validates user creation
   - Checks directory structure
   - Tests sudo permissions
   - Verifies WSL-specific features

3. **`scripts/setup/install-mesh-ops-tools.sh`** (To be created)
   - Will install development tools
   - Configure user environment
   - Set up AI tool access

## Quick Start

```bash
# 1. Create the mesh-ops user
chmod +x scripts/setup/create-mesh-ops-user.sh
./scripts/setup/create-mesh-ops-user.sh

# 2. Validate the setup
chmod +x scripts/setup/validate-mesh-ops.sh
./scripts/setup/validate-mesh-ops.sh

# 3. Test access
sudo su - mesh-ops
```

## Configuration Structure

```yaml
/home/mesh-ops/
├── .config/
│   ├── mesh-ops/
│   │   └── config.yaml      # Node-specific configuration
│   └── systemd/user/         # User services
├── .local/
│   ├── bin/                  # User binaries (uv, bun, mise)
│   └── share/                # Application data
├── Projects/                 # Mesh-managed projects
├── Scripts/                  # Automation scripts
└── .ssh/                     # SSH configuration
```

## Sudo Permissions

The mesh-ops user has limited sudo access for:
- User-level systemctl commands
- DNF package management
- Tailscale operations
- WSL network fixes (resolv.conf, hwclock)

## Network Architecture

```yaml
node:
  hostname: wsl-fedora-kbc
  mesh_ip: 100.88.131.44
  role: development
  
peers:
  - hetzner-hq: 100.84.151.58  # Production hub
  - laptop-hq: 100.84.2.8       # Roaming workstation
```

## Phase 2.8 Checklist

- [x] Create mesh-ops user creation script
- [x] Create validation script
- [x] Document WSL-specific adaptations
- [ ] Create user on WSL node
- [ ] Install development tools
- [ ] Configure SSH access
- [ ] Set up Syncthing
- [ ] Deploy user services

## Next Steps (Phase 2.9+)

1. **Development Tools Installation**
   - Install uv, bun, mise via install script
   - Configure fish shell
   - Set up development environment

2. **Service Deployment**
   - Syncthing for file synchronization
   - Code-server for remote development
   - Jupyter for notebooks
   - Podman for containerization

3. **Agent Integration**
   - Configure AI tool access
   - Set up agent workspace
   - Implement context isolation

## Security Considerations

- User isolated from personal/work accounts
- Limited sudo permissions
- Separate secret store (future: gopass)
- No access to system configurations
- Audit trail via separate user

## Rollback Plan

If issues arise:
```bash
# Remove user and all data
sudo userdel -r mesh-ops
sudo rm -f /etc/sudoers.d/mesh-ops-wsl
```

## References

- Main Phase 2.8 Plan: `../mesh-infra/docs/PHASE2-8_PLAN.md`
- WSL Network Reset: `scripts/maintenance/wsl-network-reset.sh`
- Node Configuration: `config/network/wsl-network.conf`