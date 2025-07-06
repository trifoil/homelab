#!/bin/bash

cd "$(dirname "$0")"

echo "=========================================="
echo "Nginx Proxy Manager Monitoring Setup"
echo "=========================================="
echo "This script will set up monitoring for NPM using:"
echo "- Custom JSON log format for NPM"
echo "- Promtail for log collection"
echo "- Loki for log storage"
echo "- Grafana for visualization"
echo ""

# Function to prompt user for input and set default value if input is empty
prompt() {
  local prompt_message=$1
  local default_value=$2
  read -p "$prompt_message [$default_value]: " input
  echo "${input:-$default_value}"
}

# Prompt user for necessary inputs
npm_data_path=$(prompt "Enter the path to NPM data directory" "/storage/npm/data")
monitoring_base_path=$(prompt "Enter the base path for monitoring data" "/storage/npm/monitoring")
grafana_port=$(prompt "Enter Grafana port" "3000")
loki_port=$(prompt "Enter Loki port" "3100")

# Create monitoring directory structure
echo "Creating monitoring directory structure..."
mkdir -p "$monitoring_base_path"/{config-loki,config-promtail,grafana-data,loki-data}

# Set proper permissions
echo "Setting proper permissions..."
chown -R 472:472 "$monitoring_base_path/grafana-data"
chown -R 10001:10001 "$monitoring_base_path/loki-data"

# Create NPM custom logging configuration
echo "Creating NPM custom logging configuration..."

# Create custom directory in NPM data
mkdir -p "$npm_data_path/nginx/custom"

# Create http_top.conf with JSON log format
cat <<EOF > "$npm_data_path/nginx/custom/http_top.conf"
log_format json_analytics escape=json '{
       "time_local": "$time_local",
       "remote_addr": "$remote_addr",
       "request_uri": "$request_uri",
       "status": "$status",
       "server_name": "$server_name",
       "request_time": "$request_time",
       "request_method": "$request_method",
       "bytes_sent": "$bytes_sent",
       "http_host": "$http_host",
       "http_x_forwarded_for": "$http_x_forwarded_for",
       "http_cookie": "$http_cookie",
       "server_protocol": "$server_protocol",
       "upstream_addr": "$upstream_addr",
       "upstream_response_time": "$upstream_response_time",
       "ssl_protocol": "$ssl_protocol",
       "ssl_cipher": "$ssl_cipher",
       "http_user_agent": "$http_user_agent",
       "remote_user": "$remote_user"
   }';
EOF

# Create server_proxy.conf for access logging
cat <<EOF > "$npm_data_path/nginx/custom/server_proxy.conf"
access_log $npm_data_path/logs/all_proxy_access.log json_analytics;
error_log $npm_data_path/logs/all_proxy_error.log warn;
EOF

# Create logs directory if it doesn't exist
mkdir -p "$npm_data_path/logs"

# Create Loki configuration
echo "Creating Loki configuration..."
cat <<EOF > "$monitoring_base_path/config-loki/local-config.yaml"
auth_enabled: false

server:
  http_listen_port: 3100

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

ruler:
  alertmanager_url: http://localhost:9093

query_scheduler:
  max_outstanding_requests_per_tenant: 2048
EOF

# Create Promtail configuration
echo "Creating Promtail configuration..."
cat <<EOF > "$monitoring_base_path/config-promtail/config.yaml"
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
- job_name: nginx-proxy-manager
  static_configs:
  - targets:
      - localhost
    labels:
      job: nginx-proxy-manager
      __path__: /var/log/*log
EOF

# Create docker-compose.yml for monitoring stack
echo "Creating docker-compose.yml for monitoring stack..."
cat <<EOF > "$monitoring_base_path/docker-compose.yml"
version: "3.8"

networks:
  loki:

services:
  loki:
    image: grafana/loki:2.8.0
    container_name: npm-loki
    ports:
      - "$loki_port:3100"
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - loki
    volumes:
      - $monitoring_base_path/loki-data:/loki
      - $monitoring_base_path/config-loki:/etc/loki
    restart: unless-stopped

  promtail:
    image: grafana/promtail:2.8.0
    container_name: npm-promtail
    volumes:
      - $npm_data_path/logs/:/var/log
      - $monitoring_base_path/config-promtail/config.yaml:/etc/promtail/config.yaml
    networks:
      - loki
    restart: unless-stopped

  grafana:
    image: grafana/grafana:9.3.13
    container_name: npm-grafana
    environment:
      - GF_PATHS_PROVISIONING=/etc/grafana/provisioning
      - GF_AUTH_ANONYMOUS_ENABLED=false
    entrypoint:
      - sh
      - -euc
      - |
        mkdir -p /etc/grafana/provisioning/datasources
        cat <<EOF > /etc/grafana/provisioning/datasources/ds.yaml
        apiVersion: 1
        datasources:
        - name: Loki
          type: loki
          access: proxy 
          orgId: 1
          url: http://loki:3100
          basicAuth: false
          isDefault: true
          version: 1
          editable: false
        EOF
        /run.sh
    ports:
      - "$grafana_port:3000"
    networks:
      - loki
    volumes:
      - $monitoring_base_path/grafana-data:/var/lib/grafana
    restart: unless-stopped
EOF

# Create Grafana dashboard configuration
echo "Creating Grafana dashboard configuration..."
mkdir -p "$monitoring_base_path/grafana-data/dashboards"

cat <<EOF > "$monitoring_base_path/grafana-data/dashboards/npm-monitoring.json"
{
  "dashboard": {
    "id": null,
    "title": "Nginx Proxy Manager Monitoring",
    "tags": ["nginx", "proxy", "monitoring"],
    "style": "dark",
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Request Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "rate({job=\"nginx-proxy-manager\"}[5m])",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            },
            "custom": {
              "displayMode": "list"
            }
          }
        },
        "gridPos": {
          "h": 8,
          "w": 6,
          "x": 0,
          "y": 0
        }
      },
      {
        "id": 2,
        "title": "Response Status Codes",
        "type": "piechart",
        "targets": [
          {
            "expr": "sum by (status) (rate({job=\"nginx-proxy-manager\"}[5m]))",
            "refId": "A"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 6,
          "x": 6,
          "y": 0
        }
      },
      {
        "id": 3,
        "title": "Top Requested Domains",
        "type": "table",
        "targets": [
          {
            "expr": "topk(10, sum by (server_name) (rate({job=\"nginx-proxy-manager\"}[5m])))",
            "refId": "A"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 8
        }
      },
      {
        "id": 4,
        "title": "Response Time Distribution",
        "type": "histogram",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum(rate({job=\"nginx-proxy-manager\"}[5m])) by (le))",
            "refId": "A"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 16
        }
      },
      {
        "id": 5,
        "title": "HTTP Methods",
        "type": "barchart",
        "targets": [
          {
            "expr": "sum by (request_method) (rate({job=\"nginx-proxy-manager\"}[5m]))",
            "refId": "A"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 24
        }
      },
      {
        "id": 6,
        "title": "Error Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(rate({job=\"nginx-proxy-manager\", status=~\"4..|5..\"}[5m])) / sum(rate({job=\"nginx-proxy-manager\"}[5m])) * 100",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 1},
                {"color": "red", "value": 5}
              ]
            },
            "unit": "percent"
          }
        },
        "gridPos": {
          "h": 8,
          "w": 6,
          "x": 12,
          "y": 0
        }
      },
      {
        "id": 7,
        "title": "Bandwidth Usage",
        "type": "timeseries",
        "targets": [
          {
            "expr": "sum(rate({job=\"nginx-proxy-manager\"} | json | unwrap bytes_sent [5m]))",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "bytes"
          }
        },
        "gridPos": {
          "h": 8,
          "w": 6,
          "x": 12,
          "y": 8
        }
      },
      {
        "id": 8,
        "title": "Recent Logs",
        "type": "logs",
        "targets": [
          {
            "expr": "{job=\"nginx-proxy-manager\"}",
            "refId": "A"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 24,
          "x": 0,
          "y": 32
        }
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "5s"
  }
}
EOF

# Create setup instructions
echo "Creating setup instructions..."
cat <<EOF > "$monitoring_base_path/README.md"
# Nginx Proxy Manager Monitoring Setup

This directory contains the monitoring setup for Nginx Proxy Manager using Grafana, Loki, and Promtail.

## Components

- **Loki**: Log aggregation and storage
- **Promtail**: Log collection and forwarding
- **Grafana**: Visualization and dashboards

## Setup Instructions

1. **Restart NPM**: After running the setup script, restart your NPM container to apply the custom logging configuration:
   \`\`\`bash
   docker restart your-npm-container-name
   \`\`\`

2. **Start Monitoring Stack**: Navigate to this directory and start the monitoring services:
   \`\`\`bash
   cd $monitoring_base_path
   docker-compose up -d
   \`\`\`

3. **Access Grafana**: Open your browser and go to:
   - URL: http://your-server-ip:$grafana_port
   - Default credentials: admin/admin

4. **Import Dashboard**: 
   - Go to Dashboards > Import
   - Upload the file: grafana-data/dashboards/npm-monitoring.json
   - Select Loki as the data source

## Configuration Files

- \`config-loki/local-config.yaml\`: Loki configuration
- \`config-promtail/config.yaml\`: Promtail configuration
- \`docker-compose.yml\`: Container orchestration
- \`grafana-data/dashboards/npm-monitoring.json\`: Pre-configured dashboard

## Log Locations

- NPM logs: $npm_data_path/logs/
- Loki data: $monitoring_base_path/loki-data/
- Grafana data: $monitoring_base_path/grafana-data/

## Troubleshooting

1. **Check container status**:
   \`\`\`bash
   docker-compose ps
   \`\`\`

2. **View logs**:
   \`\`\`bash
   docker-compose logs -f [service-name]
   \`\`\`

3. **Verify log collection**:
   \`\`\`bash
   docker exec npm-promtail wc -l /var/log/all_proxy_access.log
   \`\`\`

## Ports

- Grafana: $grafana_port
- Loki: $loki_port
- Promtail: 9080 (internal)

## Security Notes

- Change default Grafana credentials after first login
- Consider setting up authentication for Loki
- Restrict access to monitoring ports if needed
EOF

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Restart your NPM container to apply custom logging:"
echo "   docker restart your-npm-container-name"
echo ""
echo "2. Start the monitoring stack:"
echo "   cd $monitoring_base_path"
echo "   docker-compose up -d"
echo ""
echo "3. Access Grafana at: http://your-server-ip:$grafana_port"
echo "   Default credentials: admin/admin"
echo ""
echo "4. Import the dashboard from: $monitoring_base_path/grafana-data/dashboards/npm-monitoring.json"
echo ""
echo "Configuration files created in: $monitoring_base_path"
echo ""

read -n 1 -s -r -p "Press any key to continue..." 