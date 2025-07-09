# NPM Monitoring Setup

This directory contains scripts and configurations for setting up comprehensive monitoring for NGINX Proxy Manager (NPM) using Promtail, Loki, and Grafana.

## Overview

The monitoring stack consists of:
- **Promtail**: Log collection agent that scrapes NPM logs
- **Loki**: Log aggregation system that stores and indexes logs
- **Grafana**: Visualization platform for creating dashboards and alerts

## Prerequisites

1. Docker and Docker Compose installed
2. NGINX Proxy Manager already set up with logging enabled
3. Access to the server where NPM is running

## Setup Process

### Step 1: Install NPM with Logging Support

First, run the modified NPM setup script that includes logging configuration:

```bash
cd scripts/setup/npm_setup/
chmod +x npm_setup.sh
./npm_setup.sh
```

This script will:
- Install NPM with custom JSON logging format
- Create necessary log directories
- Configure NPM to write logs in JSON format for monitoring

### Step 2: Install Monitoring Stack

Run the monitoring setup script:

```bash
cd scripts/setup/npm_monitoring_setup/
chmod +x npm_monitoring_setup.sh
./npm_monitoring_setup.sh
```

This script will:
- Install Promtail, Loki, and Grafana containers
- Configure log collection from NPM
- Set up a comprehensive monitoring dashboard
- Create necessary directories and set proper permissions
- Prompt for configurable ports (Grafana: 3000, Loki: 3100)
- Prompt for NPM logs path and monitoring data path

## Setup Configuration

During the setup process, you will be prompted for:

- **NPM logs path**: Path to NPM log files (default: `/storage/npm/logs`)
- **Monitoring data path**: Path for monitoring stack data (default: `/storage/monitoring`)
- **Grafana port**: Port for Grafana web interface (default: `3000`)
- **Loki port**: Port for Loki API (default: `3100`)

## Configuration Details

### NPM Logging Configuration

The NPM setup creates two custom configuration files:

1. **`http_top.conf`**: Defines the JSON log format with comprehensive fields
2. **`server_proxy.conf`**: Configures access and error logging

### Monitoring Stack Configuration

#### Promtail Configuration (`config-promtail/config.yaml`)
- Scrapes logs from the NPM log directory
- Sends logs to Loki for storage and indexing
- Labels logs with `job: nginx-proxy-manager`

#### Loki Configuration (`config-loki/local-config.yaml`)
- Stores logs in filesystem backend
- Configures retention and indexing settings
- Runs on port 3100 by default

#### Grafana Configuration
- Pre-configured with Loki data source
- Includes comprehensive NPM monitoring dashboard
- Runs on port 3000 by default

## Accessing the Monitoring Tools

### Grafana Dashboard
- **URL**: `http://your-server-ip:3000` (default port, configurable during setup)
- **Default credentials**: `admin/admin`
- **Dashboard**: "NPM Monitoring Dashboard" (automatically available)

### Loki API
- **URL**: `http://your-server-ip:3100` (default port, configurable during setup)
- **Purpose**: Direct access to log data and queries

## Dashboard Features

The NPM Monitoring Dashboard includes:

### Key Metrics
- **Total Requests**: Count of requests in the last hour
- **Requests per Second**: Real-time request rate
- **Error Rate**: Percentage of 4xx/5xx responses
- **Average Response Time**: Mean response time with thresholds

### Visualizations
- **Response Status Codes**: Pie chart showing status distribution
- **Requests Over Time**: Time series graph of request rate
- **Top URLs**: Table of most requested endpoints
- **Top Server Names**: Table of most active domains
- **Response Time Distribution**: 50th and 95th percentile response times
- **Bandwidth Usage**: Data transfer rates by server
- **HTTP Methods**: Distribution of GET, POST, etc.
- **SSL Protocols**: TLS version distribution
- **User Agents**: Top client applications

### Template Variables
- **Server Name**: Filter by specific domains
- **Status Code**: Filter by HTTP status codes

## Useful Loki Queries

### Basic Queries
```logql
# All NPM logs
{job="nginx-proxy-manager"}

# 404 errors only
{job="nginx-proxy-manager", status="404"}

# All error responses (4xx and 5xx)
{job="nginx-proxy-manager"} | json | status >= 400
```

### Advanced Queries
```logql
# Requests to specific domain
{job="nginx-proxy-manager", server_name="example.com"}

# Slow requests (>1 second)
{job="nginx-proxy-manager"} | json | request_time > 1

# Large responses (>1MB)
{job="nginx-proxy-manager"} | json | bytes_sent > 1048576

# Specific user agent
{job="nginx-proxy-manager"} | json | http_user_agent =~ ".*bot.*"
```

### Rate Queries
```logql
# Requests per second
rate({job="nginx-proxy-manager"}[1m])

# Error rate
sum(rate({job="nginx-proxy-manager", status=~"4..|5.."}[5m])) / sum(rate({job="nginx-proxy-manager"}[5m])) * 100
```

## Troubleshooting

### Common Issues

1. **No logs appearing in Grafana**
   - Check if NPM is generating logs: `tail -f /storage/npm/logs/all_proxy_access.log`
   - Verify Promtail is running: `docker ps | grep promtail`
   - Check Promtail logs: `docker logs <promtail-container-id>`

2. **Permission errors**
   - Ensure log directories have correct permissions
   - Run: `chown -R 1000:1000 /storage/npm/logs`

3. **Dashboard not loading**
   - Verify Loki is running: `docker ps | grep loki`
   - Check Grafana data source configuration
   - Restart Grafana container if needed

### Log Locations
- **NPM Access Logs**: `/storage/npm/logs/all_proxy_access.log`
- **NPM Error Logs**: `/storage/npm/logs/all_proxy_error.log`
- **Monitoring Data**: `/storage/monitoring/`

### Container Management
```bash
# View all monitoring containers
docker ps | grep -E "(loki|promtail|grafana)"

# Restart monitoring stack
cd /storage/monitoring
docker compose restart

# View logs
docker compose logs -f

# Stop monitoring stack
docker compose down
```

## Customization

### Adding Custom Dashboards
1. Create dashboard JSON file
2. Place in `grafana-dashboards/` directory
3. Restart Grafana container

### Modifying Log Collection
1. Edit `config-promtail/config.yaml`
2. Add new log sources or modify existing ones
3. Restart Promtail container

### Scaling the Setup
- For production environments, consider:
  - Using external databases for Loki
  - Setting up Grafana with persistent storage
  - Configuring backup and retention policies
  - Adding alerting rules

## Security Considerations

1. **Change default passwords** for Grafana
2. **Use HTTPS** for Grafana access in production
3. **Restrict network access** to monitoring ports
4. **Regular updates** of monitoring components
5. **Backup monitoring data** regularly

## Support

For issues or questions:
1. Check container logs for error messages
2. Verify configuration files are correct
3. Ensure all prerequisites are met
4. Review the troubleshooting section above 