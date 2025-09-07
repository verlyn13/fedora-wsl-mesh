#!/bin/bash
# Reset WSL network stack

echo "=== WSL Network Reset ==="
echo "This will restart the WSL network stack"
echo

# Check if running in WSL
if [ ! -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
    echo "Error: This script must be run in WSL"
    exit 1
fi

# Save current network info
echo "Current network configuration:"
ip addr show eth0
echo

read -p "Continue with network reset? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted"
    exit 0
fi

echo "Stopping network services..."

# Stop VPN services if running
if systemctl is-active --quiet tailscaled; then
    echo "Stopping Tailscale..."
    sudo tailscale down 2>/dev/null || true
    sudo systemctl stop tailscaled
fi

if sudo wg show mesh &> /dev/null; then
    echo "Stopping WireGuard..."
    sudo wg-quick down mesh 2>/dev/null || true
fi

echo "Flushing DNS cache..."
sudo resolvectl flush-caches 2>/dev/null || true

echo "Restarting systemd-networkd..."
sudo systemctl restart systemd-networkd

echo "Restarting systemd-resolved..."
sudo systemctl restart systemd-resolved

# Wait for network to come up
echo "Waiting for network..."
for i in {1..10}; do
    if ip addr show eth0 | grep -q "inet "; then
        break
    fi
    sleep 1
done

echo
echo "New network configuration:"
ip addr show eth0

echo
echo "Testing connectivity..."
if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
    echo "✓ Internet connectivity restored"
else
    echo "✗ No internet connectivity"
    echo "You may need to restart WSL:"
    echo "  wsl.exe --shutdown"
    echo "Then restart your WSL session"
fi

echo
echo "Network reset complete"
echo
echo "To restart VPN services:"
echo "  Tailscale: sudo systemctl start tailscaled && sudo tailscale up"
echo "  WireGuard: sudo wg-quick up mesh"