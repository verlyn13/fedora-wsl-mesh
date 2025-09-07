# Fedora WSL System Profile

## System Identification

### Host Environment
- **Physical Host**: KBC-JJOHNSON47
- **Organization**: University of Alaska
- **Domain**: ua.ad.alaska.edu
- **Windows Version**: Windows 11 Pro (Build 26100.4946)
- **Architecture**: x86_64

### WSL Environment
- **WSL Version**: 2.5.10.0
- **Distro Name**: Fedora Linux 42
- **Distro Type**: Container Image
- **Kernel**: 6.6.87.2-microsoft-standard-WSL2
- **Init System**: systemd (enabled)

### User Configuration
- **Primary User**: verlyn13
- **UID/GID**: 1000/1000
- **Groups**: verlyn13, adm, wheel, cdrom
- **Privileges**: Full sudo via wheel group
- **Home Directory**: /home/verlyn13

## Network Profile

### Layer 2 Configuration
- **Interface**: eth0 (Hyper-V virtual adapter)
- **MAC Address**: 00:15:5d:f9:6b:25
- **MTU**: 1280 (reduced from standard 1500)
- **Link State**: UP

### Layer 3 Configuration
- **Internal IP**: 172.17.107.118/20
- **Network**: 172.17.96.0/20
- **Broadcast**: 172.17.111.255
- **Gateway**: 172.17.96.1
- **External IP**: 137.229.236.139 (University NAT)

### DNS Configuration
```
nameserver 10.255.255.254  # WSL internal resolver
search ua.ad.alaska.edu     # University domain
```

### IPv6 Support
- **Link-Local**: fe80::215:5dff:fef9:6b25/64
- **Global**: Not configured
- **Status**: Enabled but not routed

## WSL Integration Features

### Interoperability
- **Windows Interop**: Enabled
- **Path Integration**: Windows PATH appended
- **Executable Permissions**: Enabled
- **Drive Mounting**: /mnt/c, /mnt/d, etc.

### File System
```
# /etc/wsl.conf
[automount]
enabled = true
mountFsTab = true
root = /mnt/
options = "metadata,umask=22,fmask=11"

[interop]
enabled = true
appendWindowsPath = true

[boot]
systemd = true
```

### Resource Limits
- **Memory**: Dynamic (up to 50% of Windows RAM)
- **CPU**: All cores available
- **Disk**: VHD with dynamic expansion
- **Swap**: 25% of memory size

## System Services

### Active Services
```
systemd-resolved.service    # DNS resolution
systemd-networkd.service    # Network management
sshd.service               # SSH server (port 22)
systemd-timesyncd.service  # Time synchronization
```

### Available Ports
- **22/tcp**: SSH server (0.0.0.0)
- **53/udp**: DNS stub resolver (127.0.0.53)
- **5355/udp**: LLMNR (0.0.0.0)

## Security Configuration

### Firewall
- **iptables**: Default ACCEPT (no rules)
- **nftables**: Not configured
- **Windows Defender**: Active on host
- **WSL Firewall**: Relies on NAT isolation

### Authentication
- **SSH**: Password and key authentication
- **Sudo**: NOPASSWD for wheel group
- **PAM**: Standard configuration
- **SELinux**: Disabled

### Network Security
- **IP Forwarding**: Disabled (sysctl)
- **Source Routing**: Disabled
- **ICMP Redirects**: Ignored
- **SYN Cookies**: Enabled

## Package Management

### Repository Configuration
- **Primary**: Fedora 42 official
- **Updates**: Enabled
- **Third-party**: None configured
- **Package Manager**: dnf

### Installed Packages (Key)
```
kernel-wsl2
systemd
openssh-server
net-tools
iproute
bind-utils
curl
wget
git
vim
```

## Development Environment

### Programming Languages
- **Python**: 3.13.1
- **Bash**: 5.2.32
- **Perl**: 5.40.0

### Build Tools
- **GCC**: Not installed
- **Make**: Not installed
- **Git**: 2.48.0

## Performance Characteristics

### Network Performance
- **Bandwidth**: ~1 Gbps internal
- **Latency to Gateway**: <1ms
- **External Latency**: +1-2ms WSL overhead
- **Packet Loss**: 0% internal

### System Performance
- **Boot Time**: ~2 seconds
- **Memory Usage**: ~200MB base
- **CPU Overhead**: ~2-3% for WSL
- **Disk I/O**: Limited by Windows filesystem

## Mesh Network Readiness

### Prerequisites Status
✅ TUN/TAP device available (`/dev/net/tun`)
✅ systemd enabled and running
✅ Network connectivity confirmed
✅ DNS resolution working
✅ sudo privileges available

### Installed Software
✅ Tailscale v1.86.2 (Active)
❌ WireGuard tools not installed
❌ Docker not installed
❌ Ansible not installed

### Mesh Network Status
- **Tailscale IP**: 100.88.131.44
- **Hostname**: wsl-fedora-kbc
- **Network**: Connected
- **MagicDNS**: Enabled

### Network Capabilities
- **VPN Support**: Full (TUN/TAP ready)
- **Port Forwarding**: Requires Windows configuration
- **Bridge Mode**: Not supported (NAT only)
- **Multicast**: Limited support

## Monitoring Points

### System Health
```bash
# CPU and Memory
free -h
top -b -n 1

# Disk Usage
df -h
du -sh /home/*

# Network Status
ss -tulpn
ip -s link
```

### WSL-Specific
```bash
# WSL Status
wsl.exe --status

# Interop Check
ls -la /run/WSL/

# Windows Integration
cmd.exe /c echo %USERNAME%
```

## Known Limitations

1. **Dynamic IP Assignment**: IP changes on WSL restart
2. **NAT-Only Networking**: No bridge mode support
3. **Port Accessibility**: Requires Windows firewall rules
4. **MTU Restrictions**: Limited to 1280 for stability
5. **Hardware Acceleration**: No GPU/crypto acceleration
6. **Systemd Services**: Some services incompatible with WSL
7. **Network Namespaces**: Limited functionality
8. **Raw Sockets**: Restricted capabilities

## Integration Points

### With Windows Host
- File system access via `/mnt/`
- Windows executable invocation
- Clipboard sharing
- Network sharing through NAT

### With Mesh Network
- VPN client capabilities
- SSH access point
- Development environment
- Monitoring node

## Update Schedule

- **System Updates**: Weekly (Sunday nights)
- **Security Patches**: As available
- **WSL Updates**: Via Windows Update
- **Mesh Config**: Synchronized with mesh-infra

---

*Generated: 2025-09-07*
*Node Classification: WSL Bridge Node*
*Security Level: Development*