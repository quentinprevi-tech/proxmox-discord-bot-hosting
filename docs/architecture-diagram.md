# Architecture Diagram

This document provides a high-level overview of the Proxmox Discord Bot Hosting Platform.

The goal of the project is to automate the provisioning and monitoring of Discord bot containers on a Proxmox homelab.

## High-level Architecture


<img width="1448" height="1086" alt="image" src="https://github.com/user-attachments/assets/c0354e90-cbc8-4deb-ab4a-985b8a5fd0ec" />


The admin dashboard can also create actions such as start, stop, restart and delete. These actions are placed in the action queue and processed by the Proxmox host worker.

## Main Components

### Flask Web Panel

The Flask panel provides the customer-facing order flow and the admin dashboard.

It handles:

- landing page
- order creation
- private beta access code validation
- Discord bot token validation
- Stripe Checkout session creation
- Stripe webhook handling
- order status page
- admin actions

### SQLite Database

SQLite stores the state of the platform.

It contains:

- orders
- selected plan
- bot name
- order status
- Stripe subscription status
- Proxmox CTID
- bot IP
- container status

### Stripe Checkout and Webhooks

Stripe Checkout is used for the payment flow.

Stripe webhooks notify the Flask panel when a subscription or payment status changes.

Examples:

- successful payment
- cancelled subscription
- failed payment

In this project, webhooks can trigger provisioning or suspension actions.

### Queue and Bash Workers

The Flask panel does not directly execute Proxmox commands.

Instead, it creates jobs or actions that are processed by Bash workers running on the Proxmox host.

This separates the web application from the infrastructure execution layer.

### Proxmox VE and LXC

Each Discord bot is provisioned into its own LXC container.

This provides:

- isolation
- resource limits
- independent lifecycle management
- easier monitoring
- easier deletion or suspension

### Prometheus and Grafana

Each bot container exposes metrics through Node Exporter.

The worker regenerates a Prometheus file-based service discovery file when bots are created or removed.

Prometheus scrapes the bot containers dynamically, and Grafana displays the metrics.

## Monitoring Flow

LXC Bot Container
  -> Node Exporter
  -> Prometheus
  -> Grafana

The bot targets are discovered dynamically through a Prometheus file_sd configuration.

## Provisioning Flow

1. The user creates an order through the Flask web panel.
2. Flask stores the order in SQLite.
3. Flask creates a Stripe Checkout session.
4. Stripe sends a webhook after payment or subscription changes.
5. Flask updates the order status.
6. Flask creates a provisioning job.
7. The Bash worker reads the job.
8. The worker clones the LXC template on Proxmox.
9. The worker starts the bot container.
10. The worker regenerates the Prometheus bots.json file.
11. Prometheus discovers the new bot target.
12. Grafana displays the bot metrics.

## Design Choice

A key design choice is that the Flask application does not directly manage Proxmox containers.

The panel handles business logic, while the Proxmox host executes infrastructure actions through dedicated workers.

This makes the project easier to understand, safer to operate, and closer to a real-world separation of responsibilities.
