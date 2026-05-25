# Architecture

This project is an automated Discord bot hosting platform running on a Proxmox homelab.

The goal is to provide a simple customer-facing order flow while keeping the actual provisioning logic on the Proxmox host.

## High-level flow

Customer -> Flask Web Panel -> SQLite / Stripe -> Bot Queue -> Proxmox Worker -> LXC Bot Container -> Prometheus -> Grafana

## Components

### Flask Bot Panel

The Flask application handles:

- public landing page
- order creation
- beta access code validation
- Discord token validation
- Stripe Checkout session creation
- Stripe webhook handling
- customer order tracking page
- admin dashboard

The application is served with Gunicorn.

### SQLite Database

SQLite is used to store order state and metadata:

- bot name
- selected plan
- customer contact
- order status
- Stripe customer and subscription references
- CTID
- container status
- bot IP
- provisioning timestamps

### Proxmox Host Worker

The provisioning worker runs on the Proxmox host.

It watches a queue directory and creates LXC containers from a bot template.

Responsibilities:

- read pending order jobs
- clone the bot template container
- apply CPU and RAM plan limits
- start the container
- register instance metadata
- regenerate Prometheus file_sd targets
- sync order state back to the panel

### Bot Action Worker

The action worker handles lifecycle operations:

- start
- stop
- restart
- delete

It is used by the admin dashboard and by Stripe cancellation automation.

### Stripe Integration

Stripe Checkout is used for subscription payment.

Stripe webhooks update the order lifecycle:

- successful checkout activates provisioning
- subscription cancellation suspends the bot
- failed payment marks subscription state without immediate deletion

### Monitoring

Each bot container exposes Node Exporter metrics.

Prometheus discovers bot containers dynamically using file-based service discovery.

Grafana displays each bot using the Node Exporter Full dashboard filtered by the node_bots job.

## Design Principles

- keep business logic in the panel container
- keep Proxmox actions on the Proxmox host
- avoid direct public access to admin actions
- use clear order statuses
- never automatically delete customer containers on payment failure
- keep backups at each important milestone
