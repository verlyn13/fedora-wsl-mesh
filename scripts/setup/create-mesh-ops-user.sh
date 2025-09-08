#!/bin/bash
# Phase 2.8: Create mesh-ops user for WSL2 Fedora node
# This script creates the mesh-ops user with WSL-specific configurations

set -euo pipefail

# Configuration
MESH_USER="mesh-ops"
MESH_UID=2000
MESH_GID=2000
MESH_COMMENT="Mesh Infrastructure Operations"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Phase 2.8: Creating mesh-ops user for WSL2 ===${NC}"

# Check if running in WSL2
if [[ ! -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
    echo -e "${YELLOW}Warning: Not running in WSL2 environment${NC}"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if user already exists
if id "$MESH_USER" &>/dev/null; then
    echo -e "${YELLOW}User $MESH_USER already exists${NC}"
    exit 0
fi

# Create group first
echo "Creating group $MESH_USER with GID $MESH_GID..."
sudo groupadd -g $MESH_GID $MESH_USER || {
    echo -e "${YELLOW}Group might already exist, continuing...${NC}"
}

# Create user with WSL-appropriate settings
echo "Creating user $MESH_USER..."
sudo useradd -m \
    -u $MESH_UID \
    -g $MESH_GID \
    -s /bin/bash \
    -c "$MESH_COMMENT" \
    $MESH_USER

# Add to necessary groups (WSL-specific)
echo "Adding user to groups..."
# Note: No docker group in WSL by default, will use podman
sudo usermod -aG wheel $MESH_USER

# Create directory structure
echo "Creating directory structure..."
sudo -u $MESH_USER mkdir -p /home/$MESH_USER/{.config,.local/bin,.local/share,Projects,Scripts}
sudo -u $MESH_USER mkdir -p /home/$MESH_USER/.config/systemd/user
sudo -u $MESH_USER mkdir -p /home/$MESH_USER/.ssh

# Copy SSH keys from current user if they exist
if [[ -f ~/.ssh/authorized_keys ]]; then
    echo "Copying SSH authorized keys..."
    sudo cp ~/.ssh/authorized_keys /home/$MESH_USER/.ssh/
    sudo chown $MESH_USER:$MESH_USER /home/$MESH_USER/.ssh/authorized_keys
    sudo chmod 600 /home/$MESH_USER/.ssh/authorized_keys
fi

# Set proper permissions
sudo chmod 700 /home/$MESH_USER/.ssh
sudo chown -R $MESH_USER:$MESH_USER /home/$MESH_USER/.ssh

# Create WSL-specific sudo rules
echo "Setting up sudo permissions..."
cat << EOF | sudo tee /etc/sudoers.d/mesh-ops-wsl
# WSL2 mesh-ops - limited due to WSL environment
$MESH_USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl --user *
$MESH_USER ALL=(ALL) NOPASSWD: /usr/bin/dnf update
$MESH_USER ALL=(ALL) NOPASSWD: /usr/bin/dnf install -y *
$MESH_USER ALL=(ALL) NOPASSWD: /usr/bin/tailscale *
$MESH_USER ALL=(ALL) NOPASSWD: /usr/sbin/tailscaled *
# Network management for WSL issues
$MESH_USER ALL=(ALL) NOPASSWD: /usr/bin/rm /etc/resolv.conf
$MESH_USER ALL=(ALL) NOPASSWD: /usr/bin/tee /etc/resolv.conf
$MESH_USER ALL=(ALL) NOPASSWD: /usr/sbin/hwclock -s
EOF

# Create WSL initialization script
echo "Creating WSL-specific initialization script..."
sudo -u $MESH_USER bash -c 'cat > /home/mesh-ops/.bash_profile << "EOF"
#!/bin/bash
# WSL2-specific initialization for mesh-ops

# Source bashrc if it exists
[[ -f ~/.bashrc ]] && . ~/.bashrc

# WSL2-specific environment
export WSL_DISTRO_NAME=$(cat /etc/os-release | grep "^NAME=" | cut -d'"' -f2)
export BROWSER="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"

# Fix WSL2 DNS if needed (common issue after sleep)
check_dns() {
    if ! nslookup google.com >/dev/null 2>&1; then
        echo "DNS appears broken, fixing..."
        echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf >/dev/null
        echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf >/dev/null
    fi
}

# Fix clock drift (common WSL issue)
fix_clock() {
    local time_diff=$(ntpdate -q pool.ntp.org 2>/dev/null | grep -oP "offset \K[0-9]+")
    if [[ -n "$time_diff" && "$time_diff" -gt 5 ]]; then
        echo "Clock drift detected, syncing..."
        sudo hwclock -s
    fi
}

# Add local bins to PATH
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.bun/bin:$HOME/go/bin:$PATH"

# Development environment
export EDITOR=nano
export VISUAL=nano

# Check system health on login
check_dns
fix_clock 2>/dev/null || true

# Show mesh status
if command -v tailscale &>/dev/null; then
    echo "Tailscale status:"
    tailscale status --peers=false 2>/dev/null || echo "  Not connected"
fi

echo "Logged in as mesh-ops on WSL2 node: $(hostname)"
EOF'

# Create basic bashrc
sudo -u $MESH_USER bash -c 'cat > /home/mesh-ops/.bashrc << "EOF"
# .bashrc for mesh-ops

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific aliases and functions
alias ll="ls -la"
alias status="make -C ~/Projects/fedora-wsl-mesh status 2>/dev/null || echo \"Project not yet cloned\""
alias mesh-check="tailscale status"

# Prompt
PS1="[\u@\h-mesh \W]\$ "
EOF'

# Create initial mesh-ops config
sudo -u $MESH_USER bash -c 'mkdir -p /home/mesh-ops/.config/mesh-ops'
sudo -u $MESH_USER bash -c 'cat > /home/mesh-ops/.config/mesh-ops/config.yaml << "EOF"
# Mesh-ops configuration for WSL2 node
node:
  type: wsl
  hostname: wsl-fedora-kbc
  role: development
  
network:
  mesh_ip: 100.88.131.44
  peers:
    - hetzner-hq: 100.84.151.58
    - laptop-hq: 100.84.2.8
    
environment:
  wsl: true
  limited_sudo: true
  rootless_containers: true
  
services:
  # Services to be installed in Phase 2.8+
  planned:
    - syncthing
    - code-server
    - jupyter
    - podman
EOF'

echo -e "${GREEN}✓ User $MESH_USER created successfully${NC}"
echo
echo "Next steps:"
echo "1. Test access: sudo su - $MESH_USER"
echo "2. Verify setup: ./scripts/setup/validate-mesh-ops.sh"
echo "3. Install dev tools: ./scripts/setup/install-mesh-ops-tools.sh"
echo
echo "SSH access: ssh $MESH_USER@\$(hostname) (once SSH keys are configured)"