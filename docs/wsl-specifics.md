# WSL-Specific Considerations

## Overview

This document details the unique characteristics, limitations, and optimizations required when running a mesh network node within Windows Subsystem for Linux 2 (WSL2).

## WSL2 Architecture

### Virtualization Model
- **Type**: Lightweight VM using Hyper-V
- **Kernel**: Microsoft-maintained Linux kernel
- **File System**: ext4 on virtual disk (VHD)
- **Memory**: Dynamic allocation from Windows
- **Network**: NAT with virtual switch

### Network Stack
```
Windows Host
    │
    ├── Hyper-V Virtual Switch
    │       │
    │       └── vEthernet (WSL)
    │
    └── WSL2 VM
            │
            └── eth0 (172.17.x.x/20)
```

## Key Differences from Native Linux

### 1. Dynamic IP Assignment
**Issue**: WSL2 assigns a new IP address on each restart

**Impact**:
- Service bindings may fail
- Static configurations become invalid
- Peer connections need updating

**Solution**:
```bash
# Use 0.0.0.0 for service bindings
ListenAddress 0.0.0.0

# Script to update IP in configs
#!/bin/bash
NEW_IP=$(ip -4 addr show eth0 | grep inet | awk '{print $2}' | cut -d'/' -f1)
sed -i "s/WSL_IP=.*/WSL_IP=\"$NEW_IP\"/" config/network/wsl-network.conf
```

### 2. NAT Networking
**Issue**: WSL2 uses NAT, not bridged networking

**Impact**:
- No direct inbound connections
- Port forwarding required
- Broadcast/multicast limited

**Solution**:
```powershell
# Windows PowerShell (Admin)
# Forward port from Windows to WSL
netsh interface portproxy add v4tov4 `
    listenport=51820 `
    listenaddress=0.0.0.0 `
    connectport=51820 `
    connectaddress=$(wsl hostname -I)
```

### 3. MTU Limitations
**Issue**: Default MTU causes packet fragmentation

**Impact**:
- VPN performance degradation
- Connection timeouts
- Packet loss

**Solution**:
```bash
# Set MTU for VPN interfaces
sudo ip link set dev tailscale0 mtu 1280
sudo ip link set dev wg0 mtu 1280

# WireGuard config
MTU = 1280
```

### 4. systemd Compatibility
**Issue**: Not all systemd features work in WSL2

**Impact**:
- Some services won't start
- Timer units may fail
- Resource limits ignored

**Solution**:
```bash
# Use WSL-compatible service configurations
[Service]
Type=simple  # Instead of notify
PrivateDevices=no  # WSL doesn't support all device isolation
```

## Performance Optimizations

### Memory Management
```bash
# Create .wslconfig in Windows user home
# %USERPROFILE%\.wslconfig

[wsl2]
memory=4GB  # Limit WSL memory usage
processors=4  # Limit CPU cores
swap=2GB  # Set swap size
```

### Disk I/O
```bash
# Use Linux filesystem for performance
# Avoid /mnt/c for intensive I/O operations

# Good performance
/home/user/project

# Poor performance
/mnt/c/Users/user/project
```

### Network Optimization
```bash
# Disable Windows Defender for WSL directories
# Add exclusion in Windows Security for:
# %USERPROFILE%\AppData\Local\Packages\CanonicalGroupLimited*

# Optimize TCP settings
sudo sysctl -w net.core.rmem_max=134217728
sudo sysctl -w net.core.wmem_max=134217728
sudo sysctl -w net.ipv4.tcp_rmem="4096 87380 134217728"
sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 134217728"
```

## Common Issues and Solutions

### Issue: WSL Clock Drift
**Symptom**: Time out of sync after sleep/hibernate

**Solution**:
```bash
# Force time sync
sudo hwclock -s
# Or
sudo ntpdate time.windows.com
```

### Issue: DNS Resolution Fails
**Symptom**: Cannot resolve hostnames

**Solution**:
```bash
# Fix /etc/resolv.conf
sudo rm /etc/resolv.conf
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
sudo bash -c 'echo "[network]" > /etc/wsl.conf'
sudo bash -c 'echo "generateResolvConf = false" >> /etc/wsl.conf'
```

### Issue: VPN Disconnects
**Symptom**: VPN connections drop randomly

**Solution**:
```bash
# Add keepalive to VPN configs
# Tailscale: Automatic
# WireGuard:
PersistentKeepalive = 25
```

### Issue: Port Already in Use
**Symptom**: Cannot bind to port

**Solution**:
```bash
# Check Windows port usage
netstat.exe -an | findstr :PORT

# Kill Windows process using port
taskkill.exe /F /PID <PID>
```

## WSL Integration Features

### Windows Interop
```bash
# Execute Windows commands
cmd.exe /c dir
powershell.exe Get-Process

# Open Windows applications
explorer.exe .
notepad.exe file.txt

# Access Windows environment
echo $USERPROFILE
echo $WSLENV
```

### File System Access
```bash
# Windows drives mounted at /mnt
ls /mnt/c  # C: drive
ls /mnt/d  # D: drive

# WSL filesystem from Windows
# \\wsl$\Fedora\home\user
explorer.exe \\wsl$\Fedora
```

### Clipboard Integration
```bash
# Copy to Windows clipboard
echo "text" | clip.exe

# Paste from Windows clipboard
powershell.exe Get-Clipboard
```

## Security Considerations

### Windows Firewall
- WSL traffic passes through Windows Firewall
- Inbound rules required for services
- Outbound generally allowed

### File Permissions
```bash
# WSL metadata for Windows files
# /etc/wsl.conf
[automount]
options = "metadata,umask=22,fmask=11"

# Fix permission issues
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### Process Isolation
- WSL processes visible to Windows
- Windows Defender scans WSL files
- Resource limits shared with Windows

## Monitoring WSL

### Resource Usage
```bash
# From Windows PowerShell
wsl --status
Get-Process -Name "vmmem"

# From WSL
free -h
df -h
top
```

### Network Monitoring
```bash
# WSL network stats
ip -s link show eth0
ss -tunap
netstat -i

# Windows network for WSL
netsh interface ipv4 show interfaces
Get-NetAdapter | Where-Object {$_.Name -like "*WSL*"}
```

## Best Practices

### 1. Service Management
- Use systemd for service management
- Create restart scripts for dynamic IPs
- Monitor service health regularly

### 2. Backup Strategy
- Export WSL distro regularly
- Backup configuration files
- Document customizations

### 3. Updates
- Update WSL: `wsl --update`
- Update Linux packages: `sudo dnf update`
- Coordinate with Windows updates

### 4. Development Workflow
- Use WSL filesystem for Linux tools
- Use Windows filesystem for Windows tools
- Leverage VS Code Remote-WSL

## Troubleshooting Commands

```bash
# WSL Status
wsl.exe --status
wsl.exe --list --verbose

# Network Diagnostics
ip addr show
ip route show
cat /etc/resolv.conf
nslookup google.com

# Service Status
systemctl status
journalctl -xe
dmesg | tail

# Interop Check
ls -la /run/WSL/
cat /proc/sys/fs/binfmt_misc/WSLInterop

# Reset WSL Network
wsl.exe --shutdown
# Then restart WSL
```

## Known Limitations

1. **No Bridge Networking**: Must use NAT
2. **No Raw Sockets**: Some network tools limited
3. **No Kernel Modules**: Cannot load custom modules
4. **No Nested Virtualization**: Cannot run VMs
5. **Limited GPU Access**: Basic support only
6. **No USB Direct Access**: Via Windows only
7. **File Watching Issues**: inotify limitations
8. **Systemd Restrictions**: Some features unavailable

## Optimization Checklist

- [ ] Configure .wslconfig for resources
- [ ] Set up Windows Firewall rules
- [ ] Optimize MTU for VPN
- [ ] Configure Windows Defender exclusions
- [ ] Set up automatic time sync
- [ ] Create IP update scripts
- [ ] Document port forwarding rules
- [ ] Test clipboard integration
- [ ] Verify DNS resolution
- [ ] Monitor resource usage

---

*Last Updated: 2025-09-07*
*WSL Version: 2.5.10.0*
*Applies to: WSL2 on Windows 11*