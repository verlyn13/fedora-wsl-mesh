# Mesh Network Integration

## Overview

This document describes the integration of the Fedora WSL node into the distributed mesh network infrastructure, including connectivity requirements, configuration details, and operational procedures.

## Mesh Network Topology

```
                    ┌─────────────────────┐
                    │     mesh-infra      │
                    │   (Headquarters)     │
                    └──────────┬──────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
   ┌────▼──────────┐    ┌─────▼──────┐    ┌─────────▼────────┐
   │  hetzner-hq   │    │ laptop-hq  │    │ wsl-fedora-kbc   │
   │ 100.84.151.58 │    │ 100.84.2.8 │    │  100.88.131.44   │
   │ (Primary Node)│    │  (Laptop)  │    │   (This Node)    │
   └───────────────┘    └────────────┘    └──────────────────┘
                                                    │
                                           [University Network]
                                              137.229.236.139
```

### Active Mesh Nodes

| Node Name | Tailscale IP | Role | Status | Latency | Phase |
|-----------|--------------|------|--------|---------|-------|
| wsl-fedora-kbc | 100.88.131.44 | WSL Bridge (This Node) | 🟢 Active | - | Phase 1 ✅ |
| hetzner-hq | 100.84.151.58 | Primary Server / Ansible Control | 🟢 Connected | ~460ms | Phase 2 ✅ |
| laptop-hq | 100.84.2.8 | Development Laptop / Managed Node | 🟢 Connected | ~217ms | Phase 2 ✅ |

### Node Capabilities

#### hetzner-hq (Primary)
- **Role**: Exit node, persistent storage, control node
- **Services**: Always-on services, Ansible control, monitoring
- **Location**: Cloud (Hetzner datacenter)

#### laptop-hq (Fedora Top)
- **Role**: Development workstation, AI assistant host
- **Services**: Build runner, development environment
- **Availability**: ~40% (intermittent)
- **Ansible**: Managed node (passwordless sudo configured)

#### wsl-fedora-kbc (This Node)
- **Role**: WSL/Windows bridge, university network access
- **Services**: Cross-platform integration, academic resources
- **Location**: University of Alaska network

## Node Characteristics

### Role in Mesh
- **Type**: Bridge Node
- **Function**: WSL/Windows Integration Point
- **Priority**: Secondary
- **Availability**: Business Hours (Alaska Time)

### Unique Capabilities
1. Windows filesystem access
2. University network resources
3. WSL development environment
4. Cross-platform testing

### Limitations
1. NAT-only networking
2. Dynamic IP assignment
3. Requires Windows host running
4. Limited to WSL2 constraints

## Connection Methods

### Primary: Tailscale (Recommended)

#### Installation
```bash
# Add Tailscale repository
curl -fsSL https://pkgs.tailscale.com/stable/fedora/repo.gpg | \
  sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg

curl -fsSL https://pkgs.tailscale.com/stable/fedora/tailscale.repo | \
  sudo tee /etc/yum.repos.d/tailscale.repo

# Install Tailscale
sudo dnf install -y tailscale

# Enable service
sudo systemctl enable --now tailscaled
```

#### Configuration
```bash
# Join mesh network with specific settings
sudo tailscale up \
  --hostname=wsl-fedora-kbc \
  --accept-routes \
  --accept-dns \
  --ssh

# Verify connection
tailscale status
tailscale ping [other-node]
```

#### WSL-Specific Settings
```bash
# Ensure service starts on WSL boot
sudo systemctl enable tailscaled

# Add to /etc/wsl.conf
[boot]
command = "systemctl start tailscaled"
```

### Alternative: WireGuard

#### Installation
```bash
# Install WireGuard tools
sudo dnf install -y wireguard-tools

# Create configuration directory
sudo mkdir -p /etc/wireguard
sudo chmod 700 /etc/wireguard
```

#### Configuration Template
```ini
# /etc/wireguard/mesh.conf
[Interface]
PrivateKey = [GENERATED_PRIVATE_KEY]
Address = 10.10.0.4/24
ListenPort = 51820
MTU = 1280  # Optimized for WSL

# Enable for gateway functionality
# PostUp = sysctl -w net.ipv4.ip_forward=1
# PostDown = sysctl -w net.ipv4.ip_forward=0

[Peer]
# Hetzner Primary Node
PublicKey = [HETZNER_PUBLIC_KEY]
AllowedIPs = 10.10.0.1/32
Endpoint = [HETZNER_IP]:51820
PersistentKeepalive = 25

[Peer]
# Fedora Top Mesh (Laptop)
PublicKey = [LAPTOP_PUBLIC_KEY]
AllowedIPs = 10.10.0.2/32
# No endpoint - behind NAT
```

#### Activation
```bash
# Generate keys
wg genkey | tee privatekey | wg pubkey > publickey

# Start tunnel
sudo wg-quick up mesh

# Enable on boot
sudo systemctl enable wg-quick@mesh
```

## Windows Firewall Configuration

### Required for Inbound Connections

```powershell
# Run in elevated PowerShell on Windows host

# Tailscale
New-NetFirewallRule -DisplayName "WSL2 Tailscale" `
  -Direction Inbound -Protocol UDP `
  -LocalPort 41641 -Action Allow

# WireGuard
New-NetFirewallRule -DisplayName "WSL2 WireGuard" `
  -Direction Inbound -Protocol UDP `
  -LocalPort 51820 -Action Allow

# SSH (if exposing to mesh)
New-NetFirewallRule -DisplayName "WSL2 SSH" `
  -Direction Inbound -Protocol TCP `
  -LocalPort 22 -Action Allow
```

## Mesh Services Configuration

### SSH Access
```bash
# Configure SSH for mesh access
sudo tee /etc/ssh/sshd_config.d/mesh.conf << EOF
# Mesh network SSH configuration
ListenAddress 0.0.0.0
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
AllowUsers verlyn13
EOF

sudo systemctl restart sshd
```

### DNS Configuration
```bash
# Use mesh DNS when connected
# Tailscale handles this automatically with MagicDNS

# For WireGuard, add to /etc/systemd/resolved.conf.d/mesh.conf
[Resolve]
DNS=10.10.0.1
Domains=~mesh.local
```

## Monitoring and Health Checks

### Connectivity Tests
```bash
#!/bin/bash
# scripts/check-mesh-health.sh

echo "=== Mesh Network Health Check ==="
echo "Date: $(date)"
echo

# Check Tailscale
if command -v tailscale &> /dev/null; then
    echo "Tailscale Status:"
    tailscale status --json | jq -r '.Peer[] | "\(.HostName): \(.Online)"'
else
    echo "Tailscale: Not installed"
fi

# Check WireGuard
if command -v wg &> /dev/null; then
    echo -e "\nWireGuard Status:"
    sudo wg show mesh latest-handshakes
else
    echo "WireGuard: Not installed"
fi

# Ping mesh nodes
echo -e "\nConnectivity Tests:"
for node in 10.10.0.1 10.10.0.2 10.10.0.3; do
    if ping -c 1 -W 1 $node &> /dev/null; then
        echo "✓ $node: Reachable"
    else
        echo "✗ $node: Unreachable"
    fi
done
```

### Performance Metrics
```bash
# Bandwidth test to primary node
iperf3 -c 10.10.0.1 -t 10

# Latency monitoring
mtr --report --report-cycles 10 10.10.0.1

# DNS resolution test
dig @10.10.0.1 mesh.local
```

## Synchronization with Mesh Infrastructure

### State Synchronization
```bash
# Pull latest mesh configuration
cd ../mesh-infra
git pull origin main

# Update local configuration
cp configs/nodes/wsl-fedora.yml ../fedora-wsl-mesh/config/

# Apply changes
cd ../fedora-wsl-mesh
make apply-config
```

### Reporting Status
```bash
# Generate status report
scripts/generate-status.sh > state/current-status.json

# Push to mesh-infra
cp state/current-status.json ../mesh-infra/nodes/wsl-fedora/
cd ../mesh-infra
git add nodes/wsl-fedora/current-status.json
git commit -m "Update WSL node status"
git push origin main
```

## Troubleshooting

### Common Issues

#### 1. Tailscale Won't Start
```bash
# Check systemd
systemctl status tailscaled

# Check logs
journalctl -u tailscaled -n 50

# Restart service
sudo systemctl restart tailscaled
```

#### 2. No Connectivity Through Mesh
```bash
# Check WSL network
ip addr show eth0
ip route

# Check Windows firewall
powershell.exe -Command "Get-NetFirewallRule -DisplayName 'WSL*'"

# Reset WSL network
wsl.exe --shutdown
# Then restart WSL
```

#### 3. DNS Resolution Failed
```bash
# Check resolver
resolvectl status

# Flush DNS cache
resolvectl flush-caches

# Test direct DNS
nslookup mesh.local 10.10.0.1
```

#### 4. WireGuard Handshake Failed
```bash
# Check peer configuration
sudo wg show mesh

# Verify keys match
echo "Local public key:"
cat /etc/wireguard/publickey

# Check MTU settings
ip link show dev mesh
```

## Security Considerations

### Access Control
1. Mesh traffic only via VPN
2. SSH key-only authentication
3. Firewall rules on Windows host
4. Service isolation in WSL

### Data Protection
1. All mesh traffic encrypted
2. No sensitive data in repository
3. Credentials in separate secure storage
4. Regular security updates

## Operational Procedures

### Daily Operations
```bash
# Morning startup
make mesh-start

# Status check
make mesh-status

# Evening shutdown (optional)
make mesh-stop
```

### Maintenance Windows
- **Scheduled**: Sunday 2-4 AM Alaska Time
- **Notification**: Via mesh-infra issue tracker
- **Duration**: Maximum 2 hours
- **Fallback**: Direct SSH if mesh unavailable

## Integration Testing

### Test Scenarios
1. **Basic Connectivity**: Ping all mesh nodes
2. **Service Access**: SSH to other nodes
3. **DNS Resolution**: Resolve mesh hostnames
4. **Bandwidth Test**: Transfer test files
5. **Failover Test**: Disconnect/reconnect

### Validation Checklist
- [ ] Tailscale/WireGuard active
- [ ] All peers reachable
- [ ] DNS resolution working
- [ ] SSH access functional
- [ ] Windows firewall configured
- [ ] Monitoring scripts operational
- [ ] Status reporting automated

## Next Steps

1. Install preferred VPN solution (Tailscale recommended)
2. Configure mesh connection
3. Test connectivity to other nodes
4. Set up monitoring and automation
5. Document any WSL-specific issues

---

*Last Updated: 2025-09-07*
*Mesh Network Version: 1.0*
*Node Status: Ready for Integration*