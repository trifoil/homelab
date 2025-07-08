#!/bin/bash

cd "$(dirname "$0")"

echo "Setting up NPM monitoring with Promtail, Loki, and Grafana"
echo "This script will install the monitoring stack for NGINX Proxy Manager"

# Function to prompt user for input and set default value if input is empty
prompt() {
  local prompt_message=$1
  local default_value=$2
  read -p "$prompt_message [$default_value]: " input
  echo "${input:-$default_value}"
}

# Prompt user for necessary inputs
npm_logs_path=$(prompt "Enter the path to NPM logs" "/storage/npm/logs")
monitoring_data_path=$(prompt "Enter the path for monitoring data" "/storage/monitoring")
grafana_port=$(prompt "Enter Grafana port" "3000")
loki_port=$(prompt "Enter Loki port" "3100")

# Create necessary directories
echo "Creating monitoring directories..."
mkdir -p "$monitoring_data_path"
mkdir -p "$monitoring_data_path/config-loki"
mkdir -p "$monitoring_data_path/config-promtail"
mkdir -p "$monitoring_data_path/grafana-data"
mkdir -p "$monitoring_data_path/loki-data"

# Set proper permissions
echo "Setting permissions..."
chown -R 472:472 "$monitoring_data_path/grafana-data"
chown -R 10001:10001 "$monitoring_data_path/loki-data"

# Create Loki configuration
echo "Creating Loki configuration..."
cat <<EOF > "$monitoring_data_path/config-loki/local-config.yaml"
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
cat <<EOF > "$monitoring_data_path/config-promtail/config.yaml"
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

# Create docker-compose.yaml for monitoring stack
echo "Creating docker-compose.yaml for monitoring stack..."
cat <<EOF > "$monitoring_data_path/docker-compose.yaml"
version: "3"

networks:
  loki:

services:
  loki:
    image: grafana/loki:2.8.0
    ports:
      - "$loki_port:3100"
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - loki
    volumes:
      - ./loki-data:/loki
      - ./config-loki:/etc/loki
    restart: unless-stopped

  promtail:
    image: grafana/promtail:2.8.0
    volumes:
      - $npm_logs_path:/var/log
      - ./config-promtail/config.yaml:/etc/promtail/config.yaml
    networks:
      - loki
    restart: unless-stopped

  grafana:
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
    image: grafana/grafana:9.3.13
    ports:
      - "$grafana_port:3000"
    networks:
      - loki
    volumes:
      - ./grafana-data:/var/lib/grafana
    restart: unless-stopped
EOF

# Create Grafana dashboard configuration
echo "Creating Grafana dashboard configuration..."
mkdir -p "$monitoring_data_path/grafana-dashboards"
mkdir -p "$monitoring_data_path/grafana-dashboards/datasources"

# Create datasource configuration
cat <<EOF > "$monitoring_data_path/grafana-dashboards/datasources/ds.yaml"
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

cat <<EOF > "$monitoring_data_path/grafana-dashboards/dashboard-provider.yaml"
apiVersion: 1

providers:
  - name: 'NPM Monitoring'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

# Create a comprehensive NPM monitoring dashboard
cat <<EOF > "$monitoring_data_path/grafana-dashboards/npm-monitoring-dashboard.json"
{
  "dashboard": {
    "id": null,
    "title": "NPM Monitoring Dashboard",
    "tags": ["nginx", "proxy", "monitoring"],
    "style": "dark",
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Total Requests",
        "type": "stat",
        "targets": [
          {
            "expr": "count_over_time({job=\"nginx-proxy-manager\"}[1h])",
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
            "expr": "sum by (status) (count_over_time({job=\"nginx-proxy-manager\"}[5m]))",
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
        "title": "Requests per Second",
        "type": "graph",
        "targets": [
          {
            "expr": "rate({job=\"nginx-proxy-manager\"}[1m])",
            "refId": "A"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 0
        }
      },
      {
        "id": 4,
        "title": "Top Requested URLs",
        "type": "table",
        "targets": [
          {
            "expr": "topk(10, sum by (request_uri) (count_over_time({job=\"nginx-proxy-manager\"}[1h])))",
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
        "id": 5,
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
          "x": 12,
          "y": 8
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
            "unit": "percent",
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 1},
                {"color": "red", "value": 5}
              ]
            }
          }
        },
        "gridPos": {
          "h": 8,
          "w": 6,
          "x": 0,
          "y": 16
        }
      },
      {
        "id": 7,
        "title": "Bandwidth Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate({job=\"nginx-proxy-manager\"} | json | unwrap bytes_sent [1m])) by (server_name)",
            "refId": "A"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 18,
          "x": 6,
          "y": 16
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

# Update docker-compose to include dashboard provisioning
cat <<EOF > "$monitoring_data_path/docker-compose.yaml"
version: "3"

networks:
  loki:

services:
  loki:
    image: grafana/loki:2.8.0
    ports:
      - "$loki_port:3100"
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - loki
    volumes:
      - ./loki-data:/loki
      - ./config-loki:/etc/loki
    restart: unless-stopped

  promtail:
    image: grafana/promtail:2.8.0
    volumes:
      - $npm_logs_path:/var/log
      - ./config-promtail/config.yaml:/etc/promtail/config.yaml
    networks:
      - loki
    restart: unless-stopped

  grafana:
    privileged: true
    environment:
      - GF_PATHS_PROVISIONING=/etc/grafana/provisioning
      - GF_AUTH_ANONYMOUS_ENABLED=false
    image: grafana/grafana:9.3.13
    ports:
      - "$grafana_port:3000"
    networks:
      - loki
    volumes:
      - ./grafana-data:/var/lib/grafana
      - ./grafana-dashboards:/etc/grafana/provisioning/dashboards
      - ./grafana-dashboards/datasources:/etc/grafana/provisioning/datasources
    restart: unless-stopped
EOF

# Start the monitoring stack
echo "Starting monitoring stack..."
cd "$monitoring_data_path"
docker compose up -d

echo ""
echo "Monitoring stack has been set up successfully!"
echo ""
echo "Services:"
echo "- Grafana: http://your-server-ip:$grafana_port (admin/admin)"
echo "- Loki: http://your-server-ip:$loki_port"
echo ""
echo "Configuration:"
echo "- NPM logs path: $npm_logs_path"
echo "- Monitoring data path: $monitoring_data_path"
echo ""
echo "Next steps:"
echo "1. Access Grafana at http://your-server-ip:$grafana_port"
echo "2. Login with admin/admin"
echo "3. The NPM Monitoring Dashboard should be automatically available"
echo "4. You can also create custom queries using the Loki data source"
echo ""
echo "Example Loki queries:"
echo "- {job=\"nginx-proxy-manager\"} - View all NPM logs"
echo "- {job=\"nginx-proxy-manager\", status=\"404\"} - View 404 errors"
echo "- {job=\"nginx-proxy-manager\"} | json | status >= 400 - View all errors"

read -n 1 -s -r -p "Press any key to continue..."
