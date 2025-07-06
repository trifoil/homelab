# Fedora 42 Homelab Security Guide

## Storage Partitioning Strategy (220GB Drive)

Based on your homelab services analysis, here's the recommended partitioning scheme for optimal security and performance:

### Partition Layout

```
/dev/sda1  - EFI System Partition     (512MB)     - FAT32
/dev/sda2  - Boot Partition           (1GB)       - ext4
/dev/sda3  - Root Filesystem          (20GB)      - ext4
/dev/sda4  - Home Directory           (10GB)      - ext4
/dev/sda5  - Docker Data              (50GB)      - ext4
/dev/sda6  - Application Storage      (80GB)      - ext4
/dev/sda7  - Media Storage            (50GB)      - ext4
/dev/sda8  - Swap                     (4GB)       - swap
```

### Detailed Partition Breakdown

| Partition | Size | Purpose | Security Level | Mount Point |
|-----------|------|---------|----------------|-------------|
| EFI | 512MB | Bootloader | High | `/boot/efi` |
| Boot | 1GB | Kernel/initramfs | High | `/boot` |
| Root | 20GB | System files | High | `/` |
| Home | 10GB | User data | Medium | `/home` |
| Docker | 50GB | Container data | Medium | `/var/lib/docker` |
| Apps | 80GB | Service data | Medium | `/storage` |
| Media | 50GB | Media files | Low | `/media` |
| Swap | 4GB | Virtual memory | High | `swap` |

### Storage Allocation for Services

Based on your scripts analysis, here's how to organize the 80GB `/storage` partition:

```
/storage/
├── aio/                    # Nextcloud AIO (20GB)
├── streaming/              # Deluge downloads (15GB)
├── media/                  # Jellyfin media (15GB)
├── deluge/                 # Deluge config (1GB)
├── jellyfin/               # Jellyfin config (1GB)
├── npm/                    # Nginx Proxy Manager (5GB)
│   ├── data/
│   ├── letsencrypt/
│   └── mysql/
├── homeassistant/          # Home Assistant (5GB)
├── gitbucket/              # Git repositories (8GB)
├── filebrowser/            # File manager (1GB)
├── vpn/                    # WireGuard configs (1GB)
├── vaultwarden/            # Password manager (1GB)
├── sotf/                   # Game server (5GB)
├── ddns_updater/           # DNS updates (100MB)
├── deadmanswitch/          # Monitoring (100MB)
├── portainer/              # Container management (1GB)
└── static-website/         # Static sites (1GB)
```

## Security Hardening Measures

### 1. Filesystem Security

#### Mount Options
Add these security options to `/etc/fstab`:

```bash
# Root filesystem
/dev/sda3  /  ext4  defaults,noexec,nosuid,nodev  0  1

# Boot partition
/dev/sda2  /boot  ext4  defaults,ro,noexec,nosuid,nodev  0  2

# Home directory
/dev/sda4  /home  ext4  defaults,noexec,nosuid,nodev  0  2

# Application storage
/dev/sda6  /storage  ext4  defaults,noexec,nosuid,nodev  0  2

# Media storage (less restrictive for media access)
/dev/sda7  /media  ext4  defaults,noexec,nosuid  0  2
```

#### Security Flags Explained:
- `noexec`: Prevents execution of binaries
- `nosuid`: Prevents setuid/setgid bits
- `nodev`: Prevents device file access
- `ro`: Read-only (for boot partition)

### 2. User and Permission Management

#### Create Dedicated Service User
```bash
# Create homelab user
sudo useradd -r -s /bin/false -d /var/lib/homelab homelab
sudo usermod -aG docker homelab

# Set proper ownership for storage
sudo chown -R homelab:homelab /storage
sudo chmod -R 750 /storage
```

#### Directory Permissions
```bash
# Sensitive directories
sudo chmod 700 /storage/vaultwarden
sudo chmod 700 /storage/vpn
sudo chmod 700 /storage/npm/letsencrypt

# Media directories (more permissive)
sudo chmod 755 /storage/media
sudo chmod 755 /storage/streaming

# Config directories
sudo chmod 750 /storage/*/config
```

### 3. Boot Security

#### Disable Unnecessary Boot Services
```bash
# Disable unnecessary services
sudo systemctl disable bluetooth
sudo systemctl disable cups
sudo systemctl disable avahi-daemon
sudo systemctl disable NetworkManager-wait-online
sudo systemctl disable firewalld  # If using iptables directly
```

#### Secure Boot Configuration
```bash
# Edit GRUB configuration
sudo nano /etc/default/grub

# Add these lines:
GRUB_TIMEOUT=3
GRUB_DISABLE_RECOVERY=true
GRUB_DISABLE_SUBMENU=true
GRUB_CMDLINE_LINUX_DEFAULT="quiet security=apparmor apparmor=1"

# Update GRUB
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

### 4. Network Security

#### Firewall Configuration (iptables)
```bash
# Create firewall script
sudo nano /etc/iptables/rules.v4

# Basic rules
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]

# Allow established connections
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow loopback
-A INPUT -i lo -j ACCEPT

# Allow SSH (change port if needed)
-A INPUT -p tcp --dport 22 -j ACCEPT

# Allow HTTP/HTTPS
-A INPUT -p tcp --dport 80 -j ACCEPT
-A INPUT -p tcp --dport 443 -j ACCEPT

# Allow Docker services (adjust ports as needed)
-A INPUT -p tcp --dport 8080 -j ACCEPT  # Nextcloud
-A INPUT -p tcp --dport 8096 -j ACCEPT  # Jellyfin
-A INPUT -p tcp --dport 8123 -j ACCEPT  # Home Assistant
-A INPUT -p tcp --dport 81 -j ACCEPT    # NPM Admin
-A INPUT -p tcp --dport 9443 -j ACCEPT  # Portainer

# Allow WireGuard
-A INPUT -p udp --dport 51820 -j ACCEPT

# Allow torrent traffic
-A INPUT -p tcp --dport 58846 -j ACCEPT
-A INPUT -p udp --dport 58946 -j ACCEPT

# Allow game server
-A INPUT -p udp --dport 8766 -j ACCEPT
-A INPUT -p udp --dport 27016 -j ACCEPT
-A INPUT -p udp --dport 9700 -j ACCEPT

# Allow ICMP (ping)
-A INPUT -p icmp -j ACCEPT

# Log dropped packets
-A INPUT -j LOG --log-prefix "IPTABLES-DROP: "
-A FORWARD -j LOG --log-prefix "IPTABLES-FORWARD-DROP: "

COMMIT
```

#### Enable and Start Firewall
```bash
# Install iptables-persistent
sudo dnf install iptables-services

# Enable iptables
sudo systemctl enable iptables
sudo systemctl start iptables

# Apply rules
sudo iptables-restore < /etc/iptables/rules.v4
```

### 5. Docker Security

#### Docker Daemon Security
```bash
# Create daemon.json
sudo nano /etc/docker/daemon.json

{
  "userns-remap": "homelab",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true
}
```

#### Container Security Best Practices
```bash
# Add security options to all containers
# Example for Nextcloud:
services:
  nextcloud-aio-mastercontainer:
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
      - /var/cache
      - /var/tmp
```

### 6. System Hardening

#### Kernel Parameters
```bash
# Add to /etc/sysctl.conf
sudo nano /etc/sysctl.conf

# Network security
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0

# Memory protection
vm.mmap_min_addr=65536
kernel.randomize_va_space=2

# Disable core dumps
fs.suid_dumpable=0
kernel.core_pattern=|/bin/false

# Apply changes
sudo sysctl -p
```

#### AppArmor Profiles
```bash
# Install AppArmor
sudo dnf install apparmor-utils

# Enable AppArmor
sudo systemctl enable apparmor
sudo systemctl start apparmor

# Create custom profiles for your services
sudo nano /etc/apparmor.d/docker-nextcloud
```

### 7. Monitoring and Logging

#### System Logging
```bash
# Configure rsyslog
sudo nano /etc/rsyslog.conf

# Add these lines for security logging
auth,authpriv.*                 /var/log/auth.log
kern.*                          /var/log/kern.log
daemon.*                        /var/log/daemon.log
syslog.*                        /var/log/syslog
lpr.*                           /var/log/lpr.log
user.*                          /var/log/user.log
news.crit                       /var/log/news/news.crit
news.err                        /var/log/news/news.err
news.notice                     /var/log/news/news.notice
*.=debug;\
        auth,authpriv.none;\
        news.none;mail.none     /var/log/debug
*.=info;*.=notice;*.=warn;\
        auth,authpriv.none;\
        cron,daemon.none;\
        mail,news.none          /var/log/messages
*.emerg                         :omusrmsg:*
```

#### Log Rotation
```bash
# Configure logrotate
sudo nano /etc/logrotate.d/homelab

/storage/*/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 homelab homelab
    postrotate
        systemctl reload rsyslog >/dev/null 2>&1 || true
    endscript
}
```

### 8. Backup Security

#### Encrypted Backups
```bash
# Create backup script with encryption
sudo nano /usr/local/bin/secure-backup.sh

#!/bin/bash
BACKUP_DIR="/backup"
STORAGE_DIR="/storage"
DATE=$(date +%Y%m%d_%H%M%S)
ENCRYPTION_KEY="/root/backup.key"

# Create encrypted backup
tar -czf - $STORAGE_DIR | gpg --encrypt --recipient homelab@localhost > $BACKUP_DIR/backup_$DATE.tar.gz.gpg

# Clean old backups (keep 7 days)
find $BACKUP_DIR -name "backup_*.tar.gz.gpg" -mtime +7 -delete
```

### 9. Regular Security Maintenance

#### Automated Security Updates
```bash
# Install automatic updates
sudo dnf install dnf-automatic

# Configure automatic updates
sudo nano /etc/dnf/automatic.conf

[commands]
upgrade_type = security
random_sleep = 0
download_updates = yes
apply_updates = yes

# Enable automatic updates
sudo systemctl enable dnf-automatic.timer
sudo systemctl start dnf-automatic.timer
```

#### Security Scanning
```bash
# Install security tools
sudo dnf install lynis rkhunter chkrootkit

# Run security audit
sudo lynis audit system

# Check for rootkits
sudo rkhunter --check --skip-keypress
```

### 10. Emergency Procedures

#### Incident Response Plan
1. **Isolate the system**: Disconnect from network
2. **Document the incident**: Log all activities
3. **Assess the damage**: Check logs and system integrity
4. **Contain the threat**: Stop affected services
5. **Eradicate**: Remove malware/unauthorized access
6. **Recover**: Restore from clean backup
7. **Lessons learned**: Update security measures

#### Recovery Commands
```bash
# Check system integrity
sudo rpm -Va

# Check for unauthorized changes
sudo find / -mtime -1 -ls

# Check for suspicious processes
sudo ps aux | grep -E "(cryptominer|backdoor|shell)"

# Check network connections
sudo netstat -tulpn | grep LISTEN
```

## Implementation Checklist

- [ ] Partition disk according to layout
- [ ] Apply filesystem security options
- [ ] Create dedicated service user
- [ ] Set proper directory permissions
- [ ] Configure firewall rules
- [ ] Secure Docker daemon
- [ ] Enable AppArmor
- [ ] Configure system logging
- [ ] Set up encrypted backups
- [ ] Install security monitoring tools
- [ ] Test all services after hardening
- [ ] Document all changes

## Regular Security Tasks

- [ ] Weekly: Review system logs
- [ ] Weekly: Update system packages
- [ ] Monthly: Run security audits
- [ ] Monthly: Review firewall rules
- [ ] Quarterly: Test backup restoration
- [ ] Quarterly: Update security policies

This security guide provides a comprehensive approach to securing your Fedora 42 homelab server while maintaining functionality for all your services.
