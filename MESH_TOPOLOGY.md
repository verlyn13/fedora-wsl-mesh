# Mesh Network Topology

## Network Overview

The verlyn13 mesh network consists of three interconnected nodes using Tailscale VPN, with phased deployment for progressive capabilities.

```
┌─────────────────────────────────────────────────────────────────┐
│                      MESH NETWORK INFRASTRUCTURE                │
│                         Tailscale Coordination                  │
└─────────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
┌───────▼──────────┐       ┌───────▼──────────┐       ┌────────▼─────────┐
│   HETZNER-HQ     │       │    LAPTOP-HQ     │       │  WSL-FEDORA-KBC  │
│  100.84.151.58   │       │   100.84.2.8     │       │  100.88.131.44   │
│                  │       │                  │       │                  │
│ ┌──────────────┐ │       │ ┌──────────────┐ │       │ ┌──────────────┐ │
│ │ Primary Node │ │       │ │  Workstation │ │       │ │  WSL Bridge  │ │
│ │ Control Node │ │◄──────┤ │ Managed Node │ │◄──────┤ │   Phase 1    │ │
│ │   Phase 2    │ │       │ │   Phase 2    │ │       │ │              │ │
│ └──────────────┘ │       │ └──────────────┘ │       │ └──────────────┘ │
│                  │       │                  │       │                  │
│   Cloud Server   │       │  Fedora Laptop   │       │   Windows/WSL2   │
│   Always Online  │       │  ~40% Uptime     │       │  Business Hours  │
└──────────────────┘       └──────────────────┘       └──────────────────┘
        │                           │                           │
        └───────────────────────────┼───────────────────────────┘
                                    │
                            [Internet Gateway]
```

## Node Details

### 🖥️ HETZNER-HQ (Primary Node)
- **IP**: 100.84.151.58
- **Location**: Cloud datacenter
- **OS**: Ubuntu/Debian
- **Role**: 
  - Ansible control node
  - Exit node for consistent IP
  - Persistent storage provider
  - Always-on services host
- **Phase**: 2 (Configuration Management) ✅
- **Availability**: 24/7
- **Repository**: ../hetzner

### 💻 LAPTOP-HQ (Development Workstation)
- **IP**: 100.84.2.8
- **Location**: Roaming (home/office/mobile)
- **OS**: Fedora Linux 42
- **Hardware**: Lenovo ThinkPad (16 cores, 15GB RAM)
- **Role**:
  - Development environment
  - AI assistant host (Claude Code, Codex, Gemini)
  - Build runner
  - Ansible managed node
- **Phase**: 2 (Configuration Management) ✅
- **Availability**: ~40% (intermittent)
- **Repository**: ../fedora-top-mesh

### 🪟 WSL-FEDORA-KBC (This Node)
- **IP**: 100.88.131.44
- **Location**: University of Alaska network
- **OS**: Fedora 42 on WSL2
- **Host**: Windows 11 (Build 26100)
- **Role**:
  - Windows/Linux bridge
  - University network access
  - Cross-platform development
  - Future Ansible managed node
- **Phase**: 1 (Network Foundation) ✅
- **Availability**: Business hours
- **Repository**: . (this repository)

## Network Characteristics

### Connectivity Matrix
| From/To | hetzner-hq | laptop-hq | wsl-fedora-kbc |
|---------|------------|-----------|----------------|
| **hetzner-hq** | - | ✅ Direct | ✅ Direct |
| **laptop-hq** | ✅ Direct | - | ✅ Direct |
| **wsl-fedora-kbc** | ✅ ~460ms | ✅ ~217ms | - |

### Traffic Patterns
- **Control Traffic**: hetzner-hq → all nodes (Ansible)
- **Development**: laptop-hq ↔ wsl-fedora-kbc
- **Internet Exit**: all nodes → hetzner-hq (when needed)
- **Backup/Storage**: all nodes → hetzner-hq

## Deployment Phases

### Phase 1: Network Foundation ✅
- [x] Hetzner hub deployed
- [x] Laptop connected to mesh
- [x] WSL node connected to mesh
- **Status**: Complete (3/3 nodes)

### Phase 2: Configuration Management ✅
- [x] Ansible control on hetzner-hq
- [x] Laptop configured as managed node
- [ ] WSL pending Ansible setup
- **Status**: 66% Complete (2/3 nodes)

### Phase 3: Advanced Services (Planned)
- [ ] Syncthing for file synchronization
- [ ] Monitoring and observability
- [ ] Backup automation
- [ ] Service discovery

## Security Architecture

### Authentication
- **Mesh Access**: Tailscale identity
- **SSH**: Ed25519 keys only
- **Ansible**: Dedicated ansible_ed25519 key
- **Sudo**: Passwordless for automation

### Network Security
- **Encryption**: WireGuard (via Tailscale)
- **Firewall**: Per-node (firewalld/iptables)
- **Access**: Mesh-only (no public SSH)
- **DNS**: MagicDNS for internal resolution

## Operational Considerations

### High Availability
- **Primary Services**: Run on hetzner-hq (24/7)
- **Development**: Distributed between laptop and WSL
- **Failover**: Manual (no automatic failover yet)

### Resource Allocation
- **CPU Intensive**: laptop-hq (16 cores)
- **Storage**: hetzner-hq (persistent)
- **Memory**: Distributed as needed
- **Network**: University resources via WSL

### Maintenance Windows
- **hetzner-hq**: Minimal (critical updates only)
- **laptop-hq**: Flexible (when offline)
- **wsl-fedora-kbc**: Sunday 2-4 AM AKDT

## Management Commands

### From Any Node
```bash
# Check mesh status
tailscale status

# Test connectivity
tailscale ping <node-name>
```

### From This WSL Node
```bash
# Full mesh status
make status

# Check connectivity
make check-mesh

# Network diagnostics
make diagnose
```

### From Control Node (hetzner-hq)
```bash
# Manage all nodes
ansible all -m ping
ansible-playbook playbooks/site.yaml

# Target specific node
ansible wsl-fedora-kbc -m setup
```

## Future Enhancements

1. **Phase 2 Completion**: Add WSL node to Ansible management
2. **Monitoring Stack**: Prometheus + Grafana on hetzner-hq
3. **Backup System**: Automated backups to hetzner-hq
4. **Service Mesh**: Internal service discovery
5. **Load Balancing**: Distribute services across nodes

## Repository Structure

Each node maintains its own configuration repository:
- `mesh-infra/` - Central configuration and Ansible playbooks
- `hetzner/` - Primary node configuration
- `fedora-top-mesh/` - Laptop node configuration
- `fedora-wsl-mesh/` - WSL node configuration (this repo)

---

*Generated: 2025-09-07*  
*Network Status: Operational*  
*Total Nodes: 3*  
*Phase 2 Progress: 66%*