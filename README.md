# Fedora WSL Mesh Node

## Overview

This repository manages the Fedora WSL2 instance participating in the distributed mesh network infrastructure. Running on Windows 11 within the University of Alaska network, this node provides a unique bridge between Windows/WSL environments and the broader mesh network.

**Current Phase**: 2.8 COMPLETE ✅  
**Deployment Status**: mesh-ops user operational (first node in rollout)  
**Network Status**: Connected to mesh via Tailscale

## System Context

- **Node Type**: WSL2 Fedora Instance
- **Host OS**: Windows 11 (Build 26100)
- **WSL Version**: 2.5.10.0
- **Distribution**: Fedora Linux 42 (Container Image)
- **Network Location**: University of Alaska (137.229.x.x)
- **Hostname**: KBC-JJOHNSON47.ua.ad.alaska.edu

## Repository Structure

```
fedora-wsl-mesh/
├── README.md                    # This file
├── SYSTEM_PROFILE.md           # Detailed WSL environment specifications
├── MESH_INTEGRATION.md         # Mesh network connection documentation
├── config/                     # Network and service configurations
│   ├── tailscale/             # Tailscale configuration
│   ├── wireguard/             # WireGuard configuration
│   └── network/               # General network settings
├── scripts/                    # Setup and maintenance scripts
│   ├── setup/                 # Initial setup scripts
│   ├── health/                # Health check scripts
│   └── maintenance/           # Maintenance utilities
├── docs/                       # Detailed documentation
│   ├── wsl-specifics.md      # WSL-specific considerations
│   ├── network-topology.md   # Network layout and routing
│   └── troubleshooting.md    # Common issues and solutions
└── state/                      # Runtime state and status files

```

## Mesh Network Status

### Connected Nodes
| Node | IP Address | Status | Phase 2.8 |
|------|------------|--------|----------|
| **wsl-fedora-kbc** (this) | 100.88.131.44 | 🟢 Operational | ✅ Complete |
| **laptop-hq** | 100.84.2.8 | 🟢 Operational | ✅ Complete |
| **hetzner-hq** | 100.84.151.58 | 🟢 Operational | ✅ Complete |

### mesh-ops User
- **Status**: Deployed and operational
- **UID/GID**: 2000/2000
- **Access**: `sudo su - mesh-ops` or `ssh mesh-ops@wsl-fedora-kbc`
- **Purpose**: Infrastructure operations and agent orchestration

## Quick Start

### Prerequisites

1. WSL2 with Fedora 42 installed
2. systemd enabled in WSL
3. sudo access (wheel group)
4. TUN/TAP device available

### Phase 2.8 Management Commands

```bash
# Check mesh-ops status
make mesh-user-status

# Switch to mesh-ops user
make mesh-user-switch

# Validate setup
make mesh-user-validate
```

### Initial Setup

```bash
# Clone this repository
git clone [repository-url] ~/projects/verlyn13/fedora-wsl-mesh
cd ~/projects/verlyn13/fedora-wsl-mesh

# Run initial setup
make setup

# Check system status
make status
```

### Joining the Mesh Network

```bash
# Install and configure Tailscale (recommended for WSL)
make install-tailscale
make configure-mesh

# Alternative: WireGuard setup
make install-wireguard
make configure-wireguard
```

## Network Architecture

This WSL node operates within a unique network context:

- **Internal WSL Network**: 172.17.107.118/20 (NAT, dynamic)
- **Windows Host Network**: University of Alaska (137.229.236.139)
- **Mesh Network Access**: Via Tailscale/WireGuard VPN
- **DNS Resolution**: WSL internal resolver → Windows host → University DNS

## Related Repositories

- **[../mesh-infra](../mesh-infra)**: Main mesh network headquarters
- **[../hetzner](../hetzner)**: Primary mesh node (cloud server)
- **[../fedora-top-mesh](../fedora-top-mesh)**: Laptop mesh node

## Key Features

### WSL-Specific Capabilities

- Bridge between Windows and Linux mesh nodes
- Access to Windows filesystem and applications
- Hybrid cloud/local development environment
- University network academic resources access

### Mesh Network Services

- Secure tunnel endpoint (Tailscale/WireGuard)
- Development and testing environment
- Windows interoperability layer
- Network monitoring and diagnostics

## Configuration

### Environment Variables

```bash
# WSL-specific settings
export WSL_DISTRO_NAME="fedora-42"
export WSL_INTEROP="/run/WSL/1_interop"
export MESH_NODE_NAME="wsl-fedora-kbc"
export MESH_NODE_TYPE="wsl-bridge"
```

### Network Settings

- MTU: 1280 (optimized for WSL2)
- IP Forwarding: Disabled (enable for routing)
- DNS: Auto-configured via WSL

## Maintenance

### Daily Tasks

```bash
# Check mesh connectivity
make check-mesh

# Update system status
make update-status

# Sync with mesh-infra
make sync-upstream
```

### Troubleshooting

```bash
# Run diagnostics
make diagnose

# Check WSL-specific issues
make wsl-check

# Reset network stack
make reset-network
```

## Security Considerations

1. **WSL NAT Protection**: Inherent NAT provides basic security
2. **Windows Firewall**: Requires explicit rules for inbound connections
3. **University Network**: May have additional restrictions
4. **VPN Encryption**: All mesh traffic encrypted via Tailscale/WireGuard

## Performance Notes

- **Bandwidth**: Limited by WSL2 virtual adapter
- **Latency**: Additional ~1-2ms from WSL translation
- **CPU**: No hardware acceleration for VPN encryption
- **Memory**: Shared with Windows host

## Contributing

This node follows the mesh network standards defined in `mesh-infra`. WSL-specific enhancements should be documented and tested within the constraints of the WSL2 environment.

## Status

- **Mesh Integration**: 🟢 Connected and Operational
- **Tailscale**: 🟢 Active (v1.86.2)
- **WireGuard**: ⚪ Not installed
- **System Health**: 🟢 Operational
- **Node IP**: 100.88.131.44
- **Connected Peers**: 2 (hetzner-hq, laptop-hq)

## Contact

This node is maintained as part of the verlyn13 mesh network infrastructure. For WSL-specific issues, refer to `docs/wsl-specifics.md`.

---

*Part of the distributed mesh network infrastructure*
*Node Type: WSL2 Bridge | Location: University of Alaska*