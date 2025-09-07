# Phase 2: Ansible Configuration Management - WSL Node

## Deployment Status

**Phase Started**: 2025-09-07  
**Node**: wsl-fedora-kbc  
**Tailscale IP**: 100.88.131.44  
**Role**: Managed Node (WSL Bridge)  

## Phase 2 Objectives

Transform this WSL node into an Ansible-managed system that receives automated configuration from the hetzner-hq control node.

## Current Status Checklist

### Prerequisites ✅
- [x] Python 3 installed (3.12.11)
- [x] SSH service running
- [x] Tailscale connected (100.88.131.44)
- [x] Control node reachable
- [x] SSH directory configured
- [x] Ansible key pair present locally (~/.ssh/ansible_ed25519)

### Configuration Progress
- [x] Control node SSH key authorization (ansible@hetzner.hq added to authorized_keys)
- [x] Passwordless sudo configuration (completed 2025-09-07)
- [ ] Add to control node inventory (ready for control node action)
- [ ] Ansible connectivity test (awaiting control node)
- [ ] First playbook run (awaiting control node)

## WSL Node Configuration

### System Details
```yaml
hostname: wsl-fedora-kbc
platform: wsl2_windows11
os: fedora_42
location: university_alaska
ip: 100.88.131.44
user: verlyn13
python: /usr/bin/python3
```

### WSL-Specific Considerations
1. **Dynamic IP**: WSL IP changes on restart (mitigated by Tailscale)
2. **NAT Networking**: No direct inbound connections
3. **systemd**: Partially operational in WSL
4. **Resource Sharing**: Memory/CPU shared with Windows host
5. **Availability**: Business hours (not 24/7)

## Deployment Steps

### Step 1: Authorize Control Node Access ⏳

The control node needs SSH access to manage this node.

```bash
# On this WSL node, run:
./scripts/setup/accept-control-node-key.sh

# This will guide you through adding the control node's
# ansible_ed25519.pub key to authorized_keys
```

### Step 2: Configure Passwordless Sudo ⏳

Ansible needs to run commands with sudo without password prompts.

```bash
# Generate the sudo configuration:
./scripts/setup/configure-passwordless-sudo.sh

# Then run the command it provides:
sudo /tmp/configure-sudo.sh

# Verify:
sudo -n true && echo "✓ Passwordless sudo configured"
```

### Step 3: Verify Readiness ⏳

```bash
# Run comprehensive check:
./scripts/setup/ansible-readiness-check.sh

# All items should show green checkmarks
```

### Step 4: Control Node Configuration ⏳

On the control node (hetzner-hq), add this node to inventory:

```yaml
# In /opt/mesh-infra/ansible/inventory/hosts.yaml
all:
  children:
    wsl_nodes:
      hosts:
        wsl-fedora-kbc:
          ansible_host: 100.88.131.44
          ansible_user: verlyn13
          ansible_python_interpreter: /usr/bin/python3
          device_type: wsl
          os: fedora
          location: university_alaska
          platform: wsl2_windows11
          groups:
            - workstations
            - wsl_nodes
```

### Step 5: Test Connectivity ⏳

From the control node:

```bash
# Test basic connectivity
ansible wsl-fedora-kbc -m ping

# Gather facts
ansible wsl-fedora-kbc -m setup

# Run ad-hoc command
ansible wsl-fedora-kbc -m command -a "hostname"
```

### Step 6: Apply Configuration ⏳

From the control node:

```bash
# Run common role
ansible-playbook -l wsl-fedora-kbc playbooks/common.yaml

# Run full site configuration
ansible-playbook -l wsl-fedora-kbc playbooks/site.yaml
```

## Expected Configurations

### From Common Role
- System packages (tmux, htop, ripgrep, fzf)
- Shell configurations
- Time synchronization
- System monitoring tools

### From Security Role  
- SSH hardening
- Firewall rules (WSL-aware)
- Fail2ban configuration
- Security updates

### From WSL-Specific Role
- WSL-optimized settings
- Windows interop configurations
- Clock sync fixes
- Network stability improvements

## Integration with Mesh Network

### Service Discovery
Once managed by Ansible, this node will:
- Register services with mesh
- Report health status
- Participate in monitoring

### Cross-Node Operations
- File synchronization via Syncthing
- Shared development environments
- Distributed builds

## Troubleshooting

### Common Issues

#### SSH Key Not Working
```bash
# Check key permissions
ls -la ~/.ssh/authorized_keys  # Should be 644
ls -la ~/.ssh/  # Should be 700

# Check SSH logs
journalctl -u sshd -n 50
```

#### Sudo Still Asks for Password
```bash
# Check sudoers file exists
ls -la /etc/sudoers.d/ansible-*

# Verify configuration
sudo -l | grep NOPASSWD
```

#### Ansible Can't Connect
```bash
# From WSL node, check:
tailscale status
ss -tlnp | grep :22

# From control node:
ssh -i ~/.ssh/ansible_ed25519 verlyn13@100.88.131.44
```

### WSL-Specific Issues

#### Clock Drift
```bash
# Fix time sync
sudo hwclock -s
```

#### Network Lost After Sleep
```bash
# Reset network
make reset-network
```

## Verification Commands

Run these to confirm Phase 2 completion:

```bash
# On WSL node:
./scripts/setup/ansible-readiness-check.sh

# From control node:
ansible wsl-fedora-kbc -m ping
ansible wsl-fedora-kbc -m command -a "echo 'Phase 2 Complete'"
```

## Benefits of Phase 2

✅ **Centralized Management**: All configuration in Git  
✅ **Consistency**: Same tools/settings across all nodes  
✅ **Security**: Automated security updates and hardening  
✅ **Efficiency**: No manual configuration needed  
✅ **Compliance**: Enforced standards and policies  

## Next Steps (Phase 3)

After Phase 2 completion:
1. File synchronization with Syncthing
2. Monitoring and metrics collection
3. Log aggregation
4. Backup automation
5. Service mesh implementation

## Status Tracking

| Task | Status | Completed | Notes |
|------|--------|-----------|-------|
| Python installed | ✅ | 2025-09-07 | v3.12.11 |
| SSH service | ✅ | 2025-09-07 | Running |
| Tailscale connected | ✅ | 2025-09-07 | 100.88.131.44 |
| SSH key authorized | ✅ | 2025-09-07 | ansible@hetzner.hq |
| Ansible key locally | ✅ | 2025-09-07 | ~/.ssh/ansible_ed25519 |
| Passwordless sudo | ✅ | 2025-09-07 | Configured |
| Added to inventory | ⏳ | - | Ready for control node |
| Connectivity test | ⏳ | - | Ready for control node |
| First playbook | ⏳ | - | Ready for control node |

---

**Current Phase**: 2 - Configuration Management  
**Progress**: 80% (WSL node fully prepared, awaiting control node actions)  
**Next Action**: Control node needs to add this node to inventory and test connectivity