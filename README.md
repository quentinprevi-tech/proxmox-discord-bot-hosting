# Proxmox Discord Bot Hosting Platform

Automated Discord bot hosting platform built on a Proxmox homelab.

This project provisions Discord bots into isolated LXC containers, exposes a customer order flow through a Flask web panel, integrates Stripe Checkout/Webhooks for subscription lifecycle management, and monitors provisioned containers dynamically with Prometheus and Grafana.

> This repository is a portfolio/documentation version of the project. Production secrets, private configuration files, customer data and internal backups are intentionally excluded.

## Features

- Flask customer panel with Basic / Plus / Pro plans
- Private beta access code
- Discord bot token validation before provisioning
- Stripe Checkout subscription flow
- Stripe webhook automation
- Automatic LXC provisioning on Proxmox
- Bash workers managed by systemd
- Admin dashboard for orders and container actions
- Automatic suspension when a Stripe subscription is cancelled
- Prometheus dynamic file service discovery
- Grafana Node Exporter monitoring per bot container
- Clean backup/versioning workflow

## Stack

- Proxmox VE
- LXC containers
- Debian
- Flask
- SQLite
- Gunicorn
- Stripe Checkout / Webhooks
- Bash
- systemd
- Prometheus
- Grafana
- Node Exporter
- Tailscale Funnel

## Current Status

This is a private beta / homelab project.

The platform currently supports order creation, beta access protection, rate limiting, Stripe subscription flow, automatic container provisioning, automatic suspension on subscription cancellation, dynamic Prometheus/Grafana monitoring, and an admin dashboard for lifecycle management.

## Security Notes

This repository does not include production secrets.

Never commit Discord bot tokens, Stripe API keys, webhook secrets, admin passwords, Flask secret keys, SQLite production databases, internal backups, private IPs or internal URLs.

## Roadmap

- Add customer documentation for Discord bot token creation
- Improve client-facing order status page
- Add email notifications
- Add upgrade/downgrade plan handling
- Add stronger token encryption at rest
- Add per-client dashboard access
- Improve deployment automation
