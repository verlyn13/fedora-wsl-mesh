#!/bin/bash
# Tailscale configuration script for WSL node

set -e

# Load network configuration
source /home/verlyn13/projects/verlyn13/fedora-wsl-mesh/config/network/wsl-network.conf

echo "=== Configuring Tailscale for WSL Mesh Node ==="
echo "Node: $NODE_NAME"
echo "Type: $NODE_TYPE"
echo

# Check if Tailscale is installed
if ! command -v tailscale &> /dev/null; then
    echo "Error: Tailscale is not installed"
    echo "Run: make install-tailscale"
    exit 1
fi

# Check if tailscaled is running
if ! systemctl is-active --quiet tailscaled; then
    echo "Starting tailscaled service..."
    sudo systemctl start tailscaled
    sleep 2
fi

# Configure Tailscale with mesh-specific settings
echo "Joining Tailscale network..."
# Use --reset to avoid conflicts with existing settings
sudo tailscale up \
    --reset \
    --hostname="$NODE_NAME" \
    --accept-routes \
    --accept-dns \
    --ssh \
    --operator="$USER"

# Wait for connection
echo "Waiting for Tailscale to connect..."
for i in {1..30}; do
    if tailscale status &> /dev/null; then
        break
    fi
    sleep 1
done

# Display status
echo
echo "=== Tailscale Status ==="
tailscale status

# Get and display IP
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "Not assigned")
echo
echo "Tailscale IPv4: $TAILSCALE_IP"

# Update configuration file with Tailscale IP
if [ "$TAILSCALE_IP" != "Not assigned" ]; then
    sed -i "s/^MESH_IP_TAILSCALE=.*/MESH_IP_TAILSCALE=\"$TAILSCALE_IP\"/" \
        /home/verlyn13/projects/verlyn13/fedora-wsl-mesh/config/network/wsl-network.conf
    echo "Configuration updated with Tailscale IP"
fi

echo
echo "=== Tailscale configuration complete ==="
echo "To disconnect: sudo tailscale down"
echo "To check status: tailscale status"