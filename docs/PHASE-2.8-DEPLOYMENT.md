# Phase 2.8 Deployment Guide: WSL Node

## Overview

This guide provides step-by-step instructions for deploying the mesh-ops user on the fedora-wsl-mesh node as part of the Phase 2.8 rollout.

## Prerequisites

- [x] Fedora WSL2 node running and accessible
- [x] Tailscale installed and connected
- [x] Scripts prepared in `scripts/setup/`
- [x] Makefile updated with mesh-ops targets

## Deployment Order

Following the risk mitigation strategy from mesh-infra:

1. **WSL Node (This Guide)** - Lowest risk, isolated environment
2. **Laptop Node** - Roaming workstation
3. **Hetzner Hub** - Production hub, deploy last

## Step-by-Step Deployment

### Step 1: Verify Repository State

```bash
# Ensure you're in the correct directory
cd ~/Projects/verlyn13/fedora-wsl-mesh

# Check current status
make status

# Verify no mesh-ops user exists
make mesh-user-status
```

### Step 2: Create Mesh-Ops User

```bash
# Create the mesh-ops user with WSL-specific configuration
make mesh-user-create

# Expected output:
# ✓ User mesh-ops created successfully
# Next steps provided
```

### Step 3: Validate Setup

```bash
# Run comprehensive validation
make mesh-user-validate

# All critical tests should pass
# Warnings are acceptable for not-yet-installed tools
```

### Step 4: Test Access

```bash
# Test switching to mesh-ops user
make mesh-user-switch

# You should now be logged in as mesh-ops
# Type 'exit' to return to your user
```

Alternative test:
```bash
# Direct SSH test (if SSH keys are configured)
ssh mesh-ops@localhost
```

### Step 5: Verify Configuration

As mesh-ops user:
```bash
# Switch to mesh-ops
sudo su - mesh-ops

# Check environment
echo $HOME           # Should be /home/mesh-ops
echo $USER           # Should be mesh-ops
pwd                  # Should be /home/mesh-ops

# Check configuration
cat ~/.config/mesh-ops/config.yaml

# Test network
ping -c 1 google.com
tailscale status

# Exit back to your user
exit
```

## Integration with Mesh-Infra

The fedora-wsl-mesh implementation aligns with mesh-infra's architecture:

### Consistent Elements
- Username: `mesh-ops`
- UID/GID: `2000`
- Home: `/home/mesh-ops`
- Config location: `~/.config/mesh-ops/`

### WSL-Specific Adaptations
- No Docker group (will use rootless Podman)
- DNS fix functions in profile
- Clock sync functions
- Limited sudo permissions
- Windows interop paths

## Quick Commands Reference

```bash
# User management
make mesh-user-create      # Create mesh-ops user
make mesh-user-validate    # Validate setup
make mesh-user-switch      # Switch to mesh-ops
make mesh-user-status      # Check user status
make mesh-user-remove      # Remove user (rollback)

# Future (Phase 2.9+)
make mesh-user-bootstrap   # Install dev tools
```

## Troubleshooting

### User Creation Fails

```bash
# Check if user partially exists
id mesh-ops

# Remove partial installation
sudo userdel mesh-ops
sudo rm -rf /home/mesh-ops
sudo rm -f /etc/sudoers.d/mesh-ops-wsl

# Retry creation
make mesh-user-create
```

### Cannot Switch to User

```bash
# Check user exists
getent passwd mesh-ops

# Check home directory
ls -la /home/mesh-ops

# Manual switch with debug
sudo su - mesh-ops -c 'echo "Login successful"'
```

### DNS Issues After Creation

```bash
# As mesh-ops user
sudo rm /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

### Clock Drift Issues

```bash
# As mesh-ops user
sudo hwclock -s
```

## Validation Checklist

- [ ] User created with UID 2000
- [ ] Home directory exists at /home/mesh-ops
- [ ] Can switch to mesh-ops user
- [ ] Sudo permissions work for allowed commands
- [ ] Configuration file exists
- [ ] Bash profile loads without errors
- [ ] Network connectivity works
- [ ] Tailscale accessible

## Next Steps

After successful deployment on WSL:

1. **Document any WSL-specific issues** encountered
2. **Report success to mesh-infra** maintainer
3. **Proceed to laptop deployment** using mesh-infra scripts
4. **Install development tools** (Phase 2.9)

## Rollback Procedure

If issues arise:

```bash
# Complete removal
make mesh-user-remove

# Verify removal
id mesh-ops  # Should fail
ls /home/mesh-ops  # Should not exist
```

## Security Notes

- mesh-ops user has limited sudo access
- Cannot modify system configurations
- Isolated from personal user data
- Separate secret store (future)
- All actions auditable via user logs

## Support

- Check `docs/PHASE-2.8-PREPARATION.md` for design details
- Review `scripts/setup/validate-mesh-ops.sh` for validation logic
- Consult mesh-infra repository for overall architecture