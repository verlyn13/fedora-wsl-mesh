#!/bin/bash
# Check if this WSL node is ready for Ansible management

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Ansible Readiness Check for WSL Node ==="
echo "Date: $(date)"
echo

# Track readiness
READY=true

# 1. Check Python (required for Ansible modules)
echo -n "Python 3: "
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
    echo -e "${GREEN}✓${NC} Installed ($PYTHON_VERSION)"
else
    echo -e "${RED}✗${NC} Not installed"
    READY=false
fi

# 2. Check SSH service
echo -n "SSH Service: "
if systemctl is-active --quiet sshd; then
    echo -e "${GREEN}✓${NC} Running"
else
    echo -e "${RED}✗${NC} Not running"
    echo "  Fix: sudo systemctl start sshd"
    READY=false
fi

# 3. Check Tailscale connectivity
echo -n "Tailscale: "
if tailscale status &> /dev/null; then
    NODE_IP=$(tailscale ip -4 2>/dev/null)
    echo -e "${GREEN}✓${NC} Connected ($NODE_IP)"
else
    echo -e "${RED}✗${NC} Not connected"
    echo "  Fix: make configure-mesh"
    READY=false
fi

# 4. Check control node connectivity
echo -n "Control Node (hetzner-hq): "
if tailscale ping -c 1 hetzner-hq &> /dev/null; then
    echo -e "${GREEN}✓${NC} Reachable"
else
    echo -e "${RED}✗${NC} Unreachable"
    READY=false
fi

# 5. Check SSH directory
echo -n "SSH Directory: "
if [ -d ~/.ssh ]; then
    PERMS=$(stat -c %a ~/.ssh)
    if [ "$PERMS" = "700" ]; then
        echo -e "${GREEN}✓${NC} Exists with correct permissions"
    else
        echo -e "${YELLOW}⚠${NC} Exists but permissions are $PERMS (should be 700)"
        echo "  Fix: chmod 700 ~/.ssh"
    fi
else
    echo -e "${YELLOW}⚠${NC} Does not exist"
    echo "  Fix: mkdir -p ~/.ssh && chmod 700 ~/.ssh"
fi

# 6. Check authorized_keys
echo -n "Authorized Keys: "
if [ -f ~/.ssh/authorized_keys ]; then
    KEY_COUNT=$(wc -l < ~/.ssh/authorized_keys)
    echo -e "${GREEN}✓${NC} File exists ($KEY_COUNT keys)"
    
    # Check for ansible key
    if grep -q "ansible" ~/.ssh/authorized_keys; then
        echo -e "  ${GREEN}✓${NC} Ansible key found"
    else
        echo -e "  ${YELLOW}⚠${NC} No Ansible key found"
        echo "  Fix: Run ./scripts/setup/accept-control-node-key.sh"
    fi
else
    echo -e "${YELLOW}⚠${NC} File does not exist"
    echo "  Fix: touch ~/.ssh/authorized_keys && chmod 644 ~/.ssh/authorized_keys"
fi

# 7. Check sudo access
echo -n "Sudo Access: "
if sudo -n true 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Passwordless sudo configured"
else
    if groups | grep -q wheel; then
        echo -e "${YELLOW}⚠${NC} Has sudo but requires password"
        echo "  Fix: Run ./scripts/setup/configure-passwordless-sudo.sh"
    else
        echo -e "${RED}✗${NC} No sudo access"
        READY=false
    fi
fi

# 8. Check firewall
echo -n "Firewall: "
if systemctl is-active --quiet firewalld; then
    # Check if SSH is allowed
    if sudo firewall-cmd --list-services 2>/dev/null | grep -q ssh; then
        echo -e "${GREEN}✓${NC} Active with SSH allowed"
    else
        echo -e "${YELLOW}⚠${NC} Active but SSH not explicitly allowed"
    fi
else
    echo -e "${GREEN}✓${NC} Not running (WSL NAT provides protection)"
fi

# 9. Check WSL-specific settings
echo -n "WSL Environment: "
if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
    echo -e "${GREEN}✓${NC} Detected"
    
    # Check systemd
    if systemctl is-system-running &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} systemd is running"
    else
        echo -e "  ${YELLOW}⚠${NC} systemd not fully operational"
    fi
else
    echo -e "${RED}✗${NC} Not in WSL environment"
    READY=false
fi

# 10. Check hostname resolution
echo -n "Hostname Resolution: "
HOSTNAME=$(hostname)
if [ "$HOSTNAME" = "wsl-fedora-kbc" ] || [ "$HOSTNAME" = "KBC-JJOHNSON47" ]; then
    echo -e "${GREEN}✓${NC} $HOSTNAME"
else
    echo -e "${YELLOW}⚠${NC} Unexpected hostname: $HOSTNAME"
    echo "  Expected: wsl-fedora-kbc"
fi

echo
echo "=== Summary ==="
if [ "$READY" = true ]; then
    echo -e "${GREEN}✓ This WSL node is ready for Ansible management${NC}"
    echo
    echo "Next steps:"
    echo "1. Ensure control node has this node in inventory"
    echo "2. From control node, test with: ansible wsl-fedora-kbc -m ping"
else
    echo -e "${RED}✗ This node is NOT ready for Ansible management${NC}"
    echo "  Fix the issues above and run this check again"
fi

echo
echo "=== Ansible Inventory Entry ==="
echo "Add this to the control node's inventory:"
echo
cat << EOF
wsl-fedora-kbc:
  ansible_host: $(tailscale ip -4 2>/dev/null || echo "100.88.131.44")
  ansible_user: $USER
  ansible_python_interpreter: /usr/bin/python3
  device_type: wsl
  os: fedora
  location: university_alaska
  platform: wsl2_windows11
EOF