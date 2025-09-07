# Troubleshooting Guide

## Quick Diagnostics

Run this command for immediate system status:
```bash
./scripts/health/check-mesh-health.sh
```

## Common Issues

### Network Connectivity

#### Problem: Cannot connect to internet
**Symptoms:**
- `ping 8.8.8.8` fails
- DNS lookups timeout
- Package installations fail

**Solutions:**
1. Check WSL network status:
   ```bash
   ip addr show eth0
   ip route show
   ```

2. Reset WSL network:
   ```bash
   ./scripts/maintenance/wsl-network-reset.sh
   ```

3. Restart WSL entirely:
   ```bash
   # From Windows PowerShell
   wsl --shutdown
   # Then restart WSL
   ```

#### Problem: Cannot reach mesh nodes
**Symptoms:**
- Ping to mesh IPs fails
- VPN shows disconnected
- No peer handshakes

**Solutions:**
1. Check VPN status:
   ```bash
   # Tailscale
   tailscale status
   
   # WireGuard
   sudo wg show mesh
   ```

2. Restart VPN services:
   ```bash
   # Tailscale
   sudo systemctl restart tailscaled
   sudo tailscale up
   
   # WireGuard
   sudo wg-quick down mesh
   sudo wg-quick up mesh
   ```

### VPN Issues

#### Problem: Tailscale won't start
**Error:** `tailscaled.service: Failed with result 'exit-code'`

**Solutions:**
1. Check service logs:
   ```bash
   journalctl -u tailscaled -n 50
   ```

2. Clear state and restart:
   ```bash
   sudo systemctl stop tailscaled
   sudo rm -rf /var/lib/tailscale/tailscaled.state
   sudo systemctl start tailscaled
   ```

3. Reinstall if necessary:
   ```bash
   sudo dnf remove tailscale
   ./scripts/setup/install-tailscale.sh
   ```

#### Problem: WireGuard no handshake
**Symptoms:**
- Latest handshake shows "none"
- Cannot ping peers
- Transfer shows 0 bytes

**Solutions:**
1. Verify configuration:
   ```bash
   sudo cat /etc/wireguard/mesh.conf
   # Check: PrivateKey, peer PublicKeys, Endpoints
   ```

2. Check firewall on Windows:
   ```powershell
   # Run in Admin PowerShell
   Get-NetFirewallRule -DisplayName "*WSL*"
   Get-NetFirewallRule -DisplayName "*WireGuard*"
   ```

3. Test connectivity to peer:
   ```bash
   # Test if peer endpoint is reachable
   nc -zv PEER_IP 51820
   ```

### DNS Problems

#### Problem: Cannot resolve hostnames
**Symptoms:**
- `nslookup google.com` fails
- `ping google.com` returns "Name or service not known"
- Package manager cannot reach repositories

**Solutions:**
1. Check DNS configuration:
   ```bash
   cat /etc/resolv.conf
   resolvectl status
   ```

2. Fix DNS resolver:
   ```bash
   # Temporary fix
   sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
   
   # Permanent fix
   sudo bash -c 'cat > /etc/wsl.conf << EOF
   [network]
   generateResolvConf = false
   EOF'
   
   # Then add your DNS servers to /etc/resolv.conf
   ```

3. Flush DNS cache:
   ```bash
   sudo resolvectl flush-caches
   sudo systemctl restart systemd-resolved
   ```

### WSL-Specific Issues

#### Problem: Clock drift after sleep
**Symptoms:**
- TLS/SSL errors
- Authentication failures
- "Certificate not yet valid" errors

**Solution:**
```bash
# Sync time with Windows
sudo hwclock -s

# Or use NTP
sudo ntpdate time.windows.com

# Make it automatic
sudo bash -c 'cat > /etc/systemd/system/time-sync.service << EOF
[Unit]
Description=Sync time with Windows
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/hwclock -s

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl enable time-sync
```

#### Problem: High memory usage
**Symptoms:**
- WSL using excessive RAM
- Windows becomes sluggish
- vmmem process using high memory

**Solution:**
1. Create memory limits:
   ```powershell
   # In Windows, create %USERPROFILE%\.wslconfig
   @"
   [wsl2]
   memory=4GB
   processors=2
   swap=2GB
   "@ | Out-File -FilePath "$env:USERPROFILE\.wslconfig" -Encoding ASCII
   ```

2. Restart WSL:
   ```bash
   wsl --shutdown
   ```

#### Problem: File permission issues
**Symptoms:**
- SSH keys rejected
- Scripts won't execute
- Permission denied errors

**Solution:**
```bash
# Fix SSH permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/*.pub
chmod 644 ~/.ssh/authorized_keys

# Fix script permissions
chmod +x scripts/**/*.sh

# Fix WSL mount permissions
sudo bash -c 'cat >> /etc/wsl.conf << EOF
[automount]
options = "metadata,umask=22,fmask=11"
EOF'
```

### Service Issues

#### Problem: SSH connection refused
**Symptoms:**
- Cannot SSH into WSL
- Port 22 connection refused
- SSH works locally but not remotely

**Solutions:**
1. Check SSH service:
   ```bash
   sudo systemctl status sshd
   sudo systemctl restart sshd
   ```

2. Verify SSH configuration:
   ```bash
   sudo sshd -t  # Test configuration
   sudo grep -E "^Port|^Listen" /etc/ssh/sshd_config
   ```

3. Set up Windows port forwarding:
   ```powershell
   # Admin PowerShell
   $wslIP = wsl hostname -I
   netsh interface portproxy add v4tov4 `
       listenport=22 `
       listenaddress=0.0.0.0 `
       connectport=22 `
       connectaddress=$wslIP
   ```

### Performance Issues

#### Problem: Slow network performance
**Symptoms:**
- High latency to mesh nodes
- Slow file transfers
- VPN throughput poor

**Solutions:**
1. Optimize MTU:
   ```bash
   # Test optimal MTU
   ping -M do -s 1472 google.com  # Decrease until no fragmentation
   
   # Set MTU
   sudo ip link set dev eth0 mtu 1280
   sudo ip link set dev tailscale0 mtu 1280
   ```

2. Disable Windows Defender for WSL:
   ```powershell
   # Add exclusion for WSL directories
   Add-MpPreference -ExclusionPath "\\wsl$"
   ```

3. Check network congestion:
   ```bash
   # Monitor network traffic
   iftop -i eth0
   nethogs
   ```

## Diagnostic Scripts

### Complete System Check
```bash
#!/bin/bash
# save as check-all.sh

echo "=== System Diagnostics ==="
date

echo -e "\n--- Network Interfaces ---"
ip -br addr show

echo -e "\n--- Routing Table ---"
ip route show

echo -e "\n--- DNS Configuration ---"
cat /etc/resolv.conf

echo -e "\n--- Service Status ---"
systemctl status sshd --no-pager | head -5
systemctl status tailscaled --no-pager | head -5 2>/dev/null || echo "Tailscale not installed"

echo -e "\n--- Connectivity Tests ---"
ping -c 1 8.8.8.8 && echo "✓ Internet OK" || echo "✗ No Internet"
ping -c 1 10.10.0.1 && echo "✓ Mesh OK" || echo "✗ No Mesh"

echo -e "\n--- Resource Usage ---"
free -h | grep Mem
df -h / | tail -1
```

### VPN Debug Script
```bash
#!/bin/bash
# save as debug-vpn.sh

echo "=== VPN Debugging ==="

if command -v tailscale &> /dev/null; then
    echo -e "\n--- Tailscale ---"
    tailscale version
    tailscale status
    tailscale netcheck
fi

if command -v wg &> /dev/null; then
    echo -e "\n--- WireGuard ---"
    wg version
    sudo wg show mesh
fi

echo -e "\n--- Firewall Rules ---"
sudo iptables -L -n -v | head -20
```

## Getting Help

### Log Locations
- System logs: `journalctl -xe`
- Tailscale logs: `journalctl -u tailscaled`
- SSH logs: `journalctl -u sshd`
- Network logs: `journalctl -u systemd-networkd`

### Useful Commands
```bash
# WSL version and status
wsl.exe --version
wsl.exe --status

# Network debugging
ss -tulpn
netstat -an
tcpdump -i eth0

# Process monitoring
htop
ps aux | grep -E "tailscale|wg"

# Service management
systemctl list-units --failed
systemctl reset-failed
```

### Contact Points
1. Check mesh-infra repository for network-wide issues
2. Consult WSL documentation for WSL-specific problems
3. Review Tailscale/WireGuard docs for VPN issues

---

*Last Updated: 2025-09-07*
*Troubleshooting Version: 1.0*