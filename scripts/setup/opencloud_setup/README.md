# OpenCloud Setup

This script installs OpenCloud with Collabora integration, configured to work behind a reverse proxy without SSL certificates.

## Features

- ✅ **No SSL certificates required** between reverse proxy and OpenCloud
- ✅ **Local network access** with configurable domain/IP and port
- ✅ **Collabora integration** with configurable server settings
- ✅ **Reverse proxy ready** - works with Nginx Proxy Manager, Traefik, etc.
- ✅ **Security optimized** for local network use

## Quick Start

1. **Run the setup script:**
   ```bash
   cd scripts/setup/opencloud_setup
   ./opencloud_setup.sh
   ```

2. **Follow the prompts:**
   - Enter your domain/IP (default: `10.10.2.115`)
   - Enter port (default: `9200`)
   - Enter Collabora server IP (default: `10.10.2.115`)
   - Enter Collabora port (default: `9980`)
   - Enter admin password (default: `admin123`)
   - Enter volume paths for config, data, and apps

3. **Access OpenCloud:**
   - URL: `http://your-domain:port`
   - Admin: `admin` / `your-password`

## Configuration

The script creates:

- **docker-compose.yml** - OpenCloud container configuration
- **CSP configuration** - Allows Collabora integration
- **Banned password list** - Security enhancement
- **Volume directories** - For persistent data

### Default Settings

- **OpenCloud:** `10.10.2.115:9200`
- **Collabora:** `10.10.2.115:9980`
- **Admin Password:** `admin123`
- **Security:** Insecure mode enabled for local network
- **Demo Users:** Disabled

## Reverse Proxy Setup

### Nginx Proxy Manager

1. Add proxy host:
   - **Domain:** Your domain/IP
   - **Scheme:** `http`
   - **Forward Hostname/IP:** `127.0.0.1`
   - **Forward Port:** `9200`
   - **SSL:** Disabled (for local setup)

2. Add Collabora proxy host:
   - **Domain:** Your domain/IP
   - **Scheme:** `http`
   - **Forward Hostname/IP:** `10.10.2.115`
   - **Forward Port:** `9980`
   - **SSL:** Disabled
   - **Path:** `/collabora`

### Traefik

Add to your `traefik.yml`:

```yaml
http:
  routers:
    opencloud:
      rule: "Host(`your-domain`)"
      service: opencloud
      entryPoints:
        - web
    
    collabora:
      rule: "Host(`your-domain`) && PathPrefix(`/collabora/`)"
      service: collabora
      entryPoints:
        - web
      stripPrefix:
        - /collabora

  services:
    opencloud:
      loadBalancer:
        servers:
          - url: "http://127.0.0.1:9200"
    
    collabora:
      loadBalancer:
        servers:
          - url: "http://10.10.2.115:9980"
```

## Collabora Integration

The setup includes Collabora integration with these features:

- **Automatic document editing** for Office files
- **WebSocket support** for real-time collaboration
- **CSP configuration** to allow Collabora connections
- **Configurable server** settings

### Testing Collabora

1. Start OpenCloud: `docker compose up -d`
2. Access OpenCloud at your configured URL
3. Create a document (Word, Excel, PowerPoint)
4. Click edit - Collabora should open for editing

### Troubleshooting Collabora

- Check if Collabora is accessible: `curl http://your-collabora-server:9980`
- Check OpenCloud logs: `docker compose logs opencloud`
- Verify CSP configuration allows Collabora connections

## Security

### Local Network Optimized

- **SSL/TLS:** Disabled between reverse proxy and OpenCloud
- **Insecure mode:** Enabled for local network
- **Basic auth:** Disabled (use reverse proxy auth instead)
- **Content Security Policy:** Configured for Collabora
- **Password policy:** Enabled with minimum requirements

### Important Security Notes

1. **Change default admin password** after first login
2. **Use reverse proxy authentication** for additional security
3. **Consider SSL/TLS** if accessing from outside local network
4. **Regular backups** of the data volume

## Management

### Docker Compose Commands

```bash
# Start OpenCloud
docker compose up -d

# Stop OpenCloud
docker compose down

# View logs
docker compose logs -f opencloud

# Check status
docker compose ps
```

### Backup and Restore

```bash
# Backup
tar -czf opencloud-backup-$(date +%Y%m%d).tar.gz /storage/opencloud/

# Restore
tar -xzf opencloud-backup-YYYYMMDD.tar.gz
```

## Troubleshooting

### Common Issues

1. **Port already in use:**
   ```bash
   sudo netstat -tlnp | grep :9200
   ```

2. **Permission denied:**
   ```bash
   chmod +x opencloud_setup.sh
   ```

3. **Docker not running:**
   ```bash
   sudo systemctl start docker
   ```

4. **Collabora not working:**
   ```bash
   curl http://your-collabora-server:9980
   docker compose logs opencloud
   ```

### Logs

```bash
# View OpenCloud logs
docker compose logs opencloud

# View real-time logs
docker compose logs -f opencloud

# Access container
docker exec -it opencloud /bin/sh
```

## Support

- OpenCloud documentation: https://docs.opencloud.eu/
- Collabora documentation: https://www.collaboraoffice.com/code/
- Docker logs: `docker compose logs opencloud` 