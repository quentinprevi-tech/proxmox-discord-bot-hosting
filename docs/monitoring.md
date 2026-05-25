# Monitoring

This project uses Prometheus and Grafana to monitor the bot hosting platform and the dynamically provisioned bot containers.

## Monitoring Stack

The monitoring stack is based on:

- Prometheus
- Grafana
- Node Exporter
- Prometheus file-based service discovery

## Dynamic Bot Discovery

Each provisioned bot container exposes Node Exporter metrics on port 9100.

When a new bot is created, the provisioning worker regenerates a Prometheus file service discovery target file.

Example target file:

    [
      {
        "targets": ["10.0.0.10:9100"],
        "labels": {
          "type": "bot",
          "client": "example-bot",
          "hostname": "example-bot",
          "ctid": "201"
        }
      }
    ]

Prometheus uses the node_bots job to scrape these dynamic bot targets.

## Prometheus Job

Example Prometheus configuration:

    - job_name: 'node_bots'
      file_sd_configs:
        - files:
            - '/etc/prometheus/file_sd/bots.json'

In the homelab setup, the file_sd directory is mounted into the Prometheus container.

## Labels

Each bot target includes labels that make filtering easier:

- type="bot"
- client="<bot-name>"
- hostname="<bot-name>"
- ctid="<proxmox-container-id>"

These labels allow Grafana dashboards to filter metrics per bot.

## Grafana Dashboard

The project reuses the Node Exporter Full dashboard for bot containers.

Dashboard variables can be set like this:

- Datasource: prometheus
- Job: node_bots
- Nodename: bot name
- Instance: bot container IP and Node Exporter port

The dashboard displays:

- CPU usage
- RAM usage
- disk usage
- system load
- uptime
- network traffic
- filesystem metrics

## Validation

The dynamic monitoring flow was validated with a test bot:

- bot name: grafana-test-bot
- job: node_bots
- Node Exporter target: redacted private IP
- Prometheus up metric: 1
- Grafana dashboard: metrics visible

## Security Notes

Monitoring is currently admin/internal only.

Customer-facing monitoring is not implemented yet.

For public documentation and screenshots, private IP addresses, internal URLs, user avatars and personal information should be redacted.
