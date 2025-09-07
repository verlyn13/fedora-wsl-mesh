#!/bin/bash
# Mesh Network Health Check Script

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Mesh Network Health Check ==="
echo "Date: $(date)"
echo "Node: $(hostname)"
echo

# Load configuration
CONFIG_FILE="/home/verlyn13/projects/verlyn13/fedora-wsl-mesh/config/network/wsl-network.conf"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    echo "Configuration loaded from: $CONFIG_FILE"
else
    echo -e "${YELLOW}Warning: Configuration file not found${NC}"
fi

echo
echo "=== System Status ==="

# Check WSL status
echo -n "WSL Environment: "
if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
    echo -e "${GREEN}✓ Running${NC}"
    echo "  WSL Version: $(wsl.exe --version 2>/dev/null | head -1 | cut -d' ' -f3 || echo "Unknown")"
else
    echo -e "${RED}✗ Not detected${NC}"
fi

# Check network interface
echo -n "Network Interface (eth0): "
if ip link show eth0 &> /dev/null; then
    echo -e "${GREEN}✓ UP${NC}"
    IP_ADDR=$(ip -4 addr show eth0 | grep inet | awk '{print $2}')
    echo "  IP Address: $IP_ADDR"
    echo "  MTU: $(ip link show eth0 | grep mtu | awk '{print $5}')"
else
    echo -e "${RED}✗ DOWN${NC}"
fi

# Check DNS resolution
echo -n "DNS Resolution: "
if nslookup google.com &> /dev/null; then
    echo -e "${GREEN}✓ Working${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
fi

echo
echo "=== VPN Status ==="

# Check Tailscale
echo -n "Tailscale: "
if command -v tailscale &> /dev/null; then
    if systemctl is-active --quiet tailscaled; then
        echo -e "${GREEN}✓ Installed and running${NC}"
        TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "Not connected")
        echo "  IP: $TAILSCALE_IP"
        
        # Check Tailscale peers with details
        if [ "$TAILSCALE_IP" != "Not connected" ]; then
            echo "  Connected Peers:"
            # Define peer roles
            declare -A PEER_ROLES=(
                ["hetzner-hq"]="Control Node"
                ["laptop-hq"]="Managed Node"
            )
            
            tailscale status | grep -v "^#" | tail -n +2 | while read line; do
                NAME=$(echo "$line" | awk '{print $2}')
                IP=$(echo "$line" | awk '{print $1}')
                STATUS=$(echo "$line" | awk '{print $NF}')
                ROLE=${PEER_ROLES[$NAME]:-"Unknown"}
                
                if [ "$STATUS" = "active" ] || [ "$STATUS" = "idle" ]; then
                    echo -e "    ${GREEN}✓${NC} $NAME ($IP) - $ROLE"
                else
                    echo -e "    ${RED}✗${NC} $NAME ($IP) - $STATUS"
                fi
            done
        fi
    else
        echo -e "${YELLOW}⚠ Installed but not running${NC}"
        echo "  Start with: sudo systemctl start tailscaled"
    fi
else
    echo -e "${YELLOW}○ Not installed${NC}"
    echo "  Install with: make install-tailscale"
fi

# Check WireGuard
echo -n "WireGuard: "
if command -v wg &> /dev/null; then
    if sudo wg show mesh &> /dev/null; then
        echo -e "${GREEN}✓ Installed and configured${NC}"
        PEERS=$(sudo wg show mesh peers | wc -l)
        echo "  Configured peers: $PEERS"
        
        # Check handshakes
        sudo wg show mesh latest-handshakes | while read peer timestamp; do
            if [ -n "$timestamp" ] && [ "$timestamp" != "0" ]; then
                LAST_HS=$(date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S')
                echo -e "    ${GREEN}✓${NC} Peer: ${peer:0:10}... Last: $LAST_HS"
            else
                echo -e "    ${RED}✗${NC} Peer: ${peer:0:10}... No handshake"
            fi
        done
    else
        echo -e "${YELLOW}⚠ Installed but not configured${NC}"
        echo "  Configure with: sudo nano /etc/wireguard/mesh.conf"
    fi
else
    echo -e "${YELLOW}○ Not installed${NC}"
    echo "  Install with: make install-wireguard"
fi

echo
echo "=== Connectivity Tests ==="

# Define mesh nodes to test - using Tailscale IPs
declare -A MESH_NODES=(
    ["hetzner-hq"]="100.84.151.58"
    ["laptop-hq"]="100.84.2.8"
)

for NODE_NAME in "${!MESH_NODES[@]}"; do
    IP="${MESH_NODES[$NODE_NAME]}"
    echo -n "$NODE_NAME ($IP): "
    
    if ping -c 1 -W 2 "$IP" &> /dev/null; then
        RTT=$(ping -c 1 -W 2 "$IP" | grep 'time=' | cut -d'=' -f4)
        echo -e "${GREEN}✓ Reachable${NC} (RTT: $RTT)"
    else
        echo -e "${RED}✗ Unreachable${NC}"
    fi
done

echo
echo "=== Service Status ==="

# Check SSH
echo -n "SSH Server: "
if systemctl is-active --quiet sshd; then
    echo -e "${GREEN}✓ Running${NC}"
    echo "  Port: $(ss -tlnp | grep sshd | awk '{print $4}' | cut -d':' -f2 | head -1)"
else
    echo -e "${RED}✗ Not running${NC}"
fi

# Check systemd-resolved
echo -n "DNS Resolver: "
if systemctl is-active --quiet systemd-resolved; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not running${NC}"
fi

echo
echo "=== Resource Usage ==="

# Memory
MEM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
MEM_USED=$(free -h | grep Mem | awk '{print $3}')
MEM_PERCENT=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100}')
echo "Memory: $MEM_USED / $MEM_TOTAL ($MEM_PERCENT%)"

# Disk
DISK_USAGE=$(df -h / | tail -1 | awk '{print $3 " / " $2 " (" $5 ")"}')
echo "Disk: $DISK_USAGE"

# Load average
LOAD=$(uptime | cut -d',' -f3- | cut -d':' -f2)
echo "Load Average:$LOAD"

echo
echo "=== Summary ==="

# Count issues
ISSUES=0
[ ! -f /proc/sys/fs/binfmt_misc/WSLInterop ] && ((ISSUES++))
! ip link show eth0 &> /dev/null && ((ISSUES++))
! nslookup google.com &> /dev/null && ((ISSUES++))

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ All systems operational${NC}"
else
    echo -e "${YELLOW}⚠ $ISSUES issue(s) detected${NC}"
fi

echo
echo "=== End of Health Check ==="#