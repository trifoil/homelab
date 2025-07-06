# Monitoring Setup Documentation

## Nginx Proxy Manager (NPM) Monitoring

This document describes the monitoring setup for Nginx Proxy Manager using Grafana, Loki, and Promtail.

### Overview

The monitoring stack consists of:
- **Nginx Proxy Manager**: Configured with custom JSON logging format
- **Promtail**: Log collection and forwarding agent
- **Loki**: Log aggregation and storage system
- **Grafana**: Visualization and dashboard platform

### Architecture

```
[Web Traffic] → [NPM] → [JSON Logs] → [Promtail] → [Loki] → [Grafana]
```

### Setup Instructions

#### 1. Run the Monitoring Setup Script

```bash
cd scripts/setup/npm_monitoring_setup/
./npm_monitoring_setup.sh
```

The script will prompt for:
- NPM data directory path (default: `/storage/npm/data`)
- Monitoring base path (default: `/storage/npm/monitoring`)
- Grafana port (default: `3000`)
- Loki port (default: `3100`)

#### 2. Restart NPM Container

After the setup script completes, restart your NPM container to apply the custom logging configuration:

```bash
docker restart your-npm-container-name
```

#### 3. Start Monitoring Stack

Navigate to the monitoring directory and start the services:

```bash
cd /storage/npm/monitoring  # or your chosen path
docker-compose up -d
```

#### 4. Access Grafana

- URL: `http://your-server-ip:3000` (or your chosen port)
- Default credentials: `admin/admin`
- **Important**: Change the default password after first login

#### 5. Import Dashboard

1. Go to Dashboards > Import in Grafana
2. Upload the file: `grafana-data/dashboards/npm-monitoring.json`
3. Select Loki as the data source

### Dashboard Features

The pre-configured dashboard includes:

1. **Request Rate**: Real-time request per second metrics
2. **Response Status Codes**: Distribution of HTTP status codes
3. **Top Requested Domains**: Most accessed domains
4. **Response Time Distribution**: 95th percentile response times
5. **HTTP Methods**: Distribution of GET, POST, etc.
6. **Error Rate**: Percentage of 4xx and 5xx errors
7. **Bandwidth Usage**: Data transfer metrics
8. **Recent Logs**: Live log stream with filtering

### Configuration Files

#### NPM Custom Logging

- **Location**: `{npm_data_path}/nginx/custom/`
- **Files**:
  - `http_top.conf`: JSON log format definition
  - `server_proxy.conf`: Access and error log configuration

#### Loki Configuration

- **File**: `config-loki/local-config.yaml`
- **Features**:
  - File-based storage
  - 24-hour index retention
  - No authentication (for development)

#### Promtail Configuration

- **File**: `config-promtail/config.yaml`
- **Features**:
  - Monitors NPM log files
  - Forwards to Loki
  - JSON parsing for structured logs

### Log Format

The custom JSON log format includes:

```json
{
  "time_local": "19/Sep/2023:15:04:54 +0000",
  "remote_addr": "192.168.10.77",
  "request_uri": "/webpage",
  "status": "200",
  "server_name": "your-domain.com",
  "request_time": "0.002",
  "request_method": "GET",
  "bytes_sent": "356",
  "http_host": "your-domain.com",
  "http_x_forwarded_for": "",
  "http_cookie": "",
  "server_protocol": "HTTP/2.0",
  "upstream_addr": "192.168.1.13:8080",
  "upstream_response_time": "0.003",
  "ssl_protocol": "TLSv1.3",
  "ssl_cipher": "TLS_AES_128_GCM_SHA256",
  "http_user_agent": "Mozilla/5.0",
  "remote_user": ""
}
```

### Directory Structure

```
/storage/npm/monitoring/
├── config-loki/
│   └── local-config.yaml
├── config-promtail/
│   └── config.yaml
├── docker-compose.yml
├── grafana-data/
│   └── dashboards/
│       └── npm-monitoring.json
├── loki-data/
└── README.md
```

### Troubleshooting

#### Check Container Status

```bash
docker-compose ps
```

#### View Service Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f loki
docker-compose logs -f promtail
docker-compose logs -f grafana
```

#### Verify Log Collection

```bash
# Check if logs are being written
docker exec npm-promtail wc -l /var/log/all_proxy_access.log

# Check log format
docker exec npm-promtail tail -1 /var/log/all_proxy_access.log
```

#### Common Issues

1. **Permission Errors**:
   ```bash
   # Fix Grafana permissions
   chown -R 472:472 grafana-data/
   
   # Fix Loki permissions
   chown -R 10001:10001 loki-data/
   ```

2. **No Logs in Grafana**:
   - Verify NPM container is restarted
   - Check Promtail can access log files
   - Ensure Loki is running and accessible

3. **Dashboard Not Loading**:
   - Verify Loki data source is configured
   - Check dashboard JSON syntax
   - Ensure time range includes data

### Security Considerations

1. **Change Default Credentials**: Update Grafana admin password
2. **Network Security**: Consider restricting access to monitoring ports
3. **Authentication**: Enable Loki authentication for production
4. **Data Retention**: Configure log retention policies
5. **Backup**: Regular backups of Grafana and Loki data

### Performance Tuning

#### Loki Configuration

- Adjust `chunk_target_size` for storage optimization
- Configure `max_cache_freshness_per_query` for query performance
- Set appropriate `retention_period` for data retention

#### Promtail Configuration

- Configure `batch_wait` and `batch_size` for optimal throughput
- Adjust `scrape_interval` based on log volume

#### Grafana Configuration

- Configure caching settings
- Adjust query timeouts
- Set appropriate refresh intervals

### Maintenance

#### Regular Tasks

1. **Monitor Disk Usage**: Check Loki and Grafana data directories
2. **Review Log Retention**: Clean up old log data
3. **Update Components**: Keep Grafana, Loki, and Promtail updated
4. **Backup Configuration**: Backup configuration files and dashboards

#### Backup Commands

```bash
# Backup Grafana data
tar -czf grafana-backup-$(date +%Y%m%d).tar.gz grafana-data/

# Backup Loki data
tar -czf loki-backup-$(date +%Y%m%d).tar.gz loki-data/

# Backup configurations
tar -czf config-backup-$(date +%Y%m%d).tar.gz config-*/
```

### Integration with Other Monitoring

This setup can be extended to monitor other services by:

1. **Adding More Log Sources**: Configure Promtail to collect logs from other containers
2. **Prometheus Integration**: Add Prometheus for metrics collection
3. **Alerting**: Configure Grafana alerting rules
4. **Centralized Logging**: Use this as a foundation for centralized logging

### References

- [Grafana Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Promtail Configuration](https://grafana.com/docs/loki/latest/clients/promtail/)
- [Nginx Log Format](https://nginx.org/en/docs/http/ngx_http_log_module.html)
- [Original Reference Article](reference_for_monitoring/Grafana_%20monitor%20Nginx%20Proxy%20Manager%20website%20_%20by%20William%20Donze%20_%20Medium.html)
