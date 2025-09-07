#!/bin/bash
# Install Tailscale on Fedora WSL

set -e

echo "=== Installing Tailscale for WSL Mesh Node ==="
echo "System: Fedora $(cat /etc/fedora-release | cut -d' ' -f3)"
echo

# Check if already installed
if command -v tailscale &> /dev/null; then
    echo "Tailscale is already installed"
    tailscale version
    exit 0
fi

# Add Tailscale repository directly for Fedora
echo "Adding Tailscale repository..."
sudo dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo 2>/dev/null || \
    curl -fsSL https://pkgs.tailscale.com/stable/fedora/tailscale.repo | \
    sudo tee /etc/yum.repos.d/tailscale.repo > /dev/null

# Update package cache
echo "Updating package cache..."
sudo dnf makecache

# Install Tailscale
echo "Installing Tailscale..."
sudo dnf install -y tailscale

# Enable tailscaled service
echo "Enabling Tailscale service..."
sudo systemctl enable tailscaled

# Start tailscaled service
echo "Starting Tailscale service..."
sudo systemctl start tailscaled

# Verify installation
echo
echo "=== Installation Complete ==="
tailscale version

echo
echo "Next steps:"
echo "1. Run: make configure-mesh"
echo "2. Or manually: sudo tailscale up"
echo
echo "Tailscale service status:"
systemctl status tailscaled --no-pager | head -10