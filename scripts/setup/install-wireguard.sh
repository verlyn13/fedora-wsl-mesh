#!/bin/bash
# Install WireGuard on Fedora WSL

set -e

echo "=== Installing WireGuard for WSL Mesh Node ==="
echo "System: Fedora $(cat /etc/fedora-release | cut -d' ' -f3)"
echo

# Check if already installed
if command -v wg &> /dev/null; then
    echo "WireGuard is already installed"
    wg version
    exit 0
fi

# Install WireGuard tools
echo "Installing WireGuard tools..."
sudo dnf install -y wireguard-tools

# Create WireGuard directory
echo "Creating WireGuard configuration directory..."
sudo mkdir -p /etc/wireguard
sudo chmod 700 /etc/wireguard

# Check kernel module (may not be available in WSL)
echo "Checking WireGuard kernel support..."
if lsmod | grep -q wireguard; then
    echo "✓ WireGuard kernel module loaded"
else
    echo "⚠ WireGuard kernel module not loaded (normal for WSL)"
    echo "  WireGuard will use userspace implementation"
fi

# Generate initial keypair
echo "Generating WireGuard keypair..."
wg genkey | sudo tee /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey > /dev/null
sudo chmod 600 /etc/wireguard/privatekey
sudo chmod 644 /etc/wireguard/publickey

# Display public key
echo
echo "=== WireGuard Public Key ==="
sudo cat /etc/wireguard/publickey
echo

# Copy template configuration
echo "Creating configuration template..."
sudo cp config/wireguard/mesh-template.conf /etc/wireguard/mesh-template.conf

# Get private key for configuration
PRIVATE_KEY=$(sudo cat /etc/wireguard/privatekey)

# Create example configuration
sudo tee /etc/wireguard/mesh.conf.example > /dev/null << EOF
# WireGuard Mesh Configuration for $(hostname)
# Generated: $(date)

[Interface]
PrivateKey = $PRIVATE_KEY
Address = 10.10.0.4/24
ListenPort = 51820
MTU = 1280

# Add peer configurations here
EOF

sudo chmod 600 /etc/wireguard/mesh.conf.example

echo "=== Installation Complete ==="
echo
echo "Next steps:"
echo "1. Edit /etc/wireguard/mesh.conf with peer information"
echo "2. Start WireGuard: sudo wg-quick up mesh"
echo "3. Enable on boot: sudo systemctl enable wg-quick@mesh"
echo
echo "Your public key (share with peers):"
sudo cat /etc/wireguard/publickey