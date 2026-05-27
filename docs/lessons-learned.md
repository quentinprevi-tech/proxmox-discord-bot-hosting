# Lessons Learned

This document summarizes the main lessons learned while building the Proxmox Discord Bot Hosting Platform.

The goal of this project was not only to make something work, but also to understand how different infrastructure, web, automation and monitoring components can work together.

## 1. Separate the web panel from infrastructure execution

One important design choice was to avoid running Proxmox commands directly from the Flask web application.

Instead, the Flask panel creates orders and jobs, while Bash workers running on the Proxmox host execute the infrastructure actions.

This separation makes the project cleaner and safer:

- Flask handles the user interface and business logic
- SQLite stores the state of the orders
- Workers execute system-level actions
- Proxmox remains the infrastructure layer

This is closer to how real systems often separate application logic from infrastructure automation.

## 2. Track state carefully

The project uses several states:

- pending
- paid
- queued
- running
- suspended
- cancelled
- hidden
- deleted

I learned that it is important to keep the database, the Proxmox containers and the monitoring configuration synchronized.

For example, a bot can exist as a container but still be missing from the database if a job fails at the wrong moment.

Because of this, synchronization scripts are important.

## 3. Backups are essential before changes

During the project, I created several backup versions before making important changes.

This made it possible to safely test new features without losing a working state.

Important lesson:

Always create a backup before modifying production-like services, databases, scripts or configuration files.

## 4. Monitoring must be dynamic

At first, monitoring static containers is simple.

However, bot containers are created dynamically, so Prometheus also needs to discover them dynamically.

Using Prometheus file-based service discovery made it possible to automatically update the list of monitored bot containers.

This avoids manually editing the Prometheus configuration each time a bot is created or removed.

## 5. systemd is useful for reliability

The project uses systemd services to keep important processes running:

- Flask/Gunicorn panel
- bot provisioning worker
- bot action worker
- Prometheus
- Grafana

This helped me understand how Linux services are started, restarted and enabled at boot.

## 6. Secrets must never be committed

The public GitHub repository is a portfolio and documentation version of the project.

It does not include:

- Discord bot tokens
- Stripe secret keys
- webhook secrets
- admin passwords
- Flask secret keys
- production SQLite databases
- internal backups
- private IP addresses or internal URLs

Instead, example environment files are used.

## 7. Stripe webhooks require careful handling

Stripe Checkout handles the payment page, but the real automation depends on webhooks.

I learned that webhooks are important because they notify the application when payment or subscription states change.

For example:

- successful payment can trigger provisioning
- cancelled subscription can trigger suspension
- failed payment can update the order status

Webhook validation is important to avoid trusting fake requests.

## 8. Homelab does not mean production-grade availability

This project runs on a homelab.

That means it is useful for learning, testing and portfolio demonstration, but it should not be presented as a production service with guaranteed availability.

Current limitations include:

- no high availability
- dependency on home internet
- dependency on home electricity
- no SLA
- limited disaster recovery automation

This is why the project is described as private beta / best effort.

## 9. Documentation is part of the project

Writing documentation helped me understand the project better.

The repository includes documentation about:

- architecture
- security
- monitoring
- roadmap
- environment variables
- screenshots

A project is easier to explain when the documentation is clear.

## 10. The project is valuable as a portfolio

Even if the project does not become a business, it is still valuable as a learning and portfolio project.

It demonstrates practical experience with:

- Proxmox VE
- LXC containers
- Flask
- SQLite
- Stripe Checkout and webhooks
- Bash scripting
- systemd
- Prometheus
- Grafana
- Node Exporter
- Git and GitHub
- backup/versioning workflow

## Conclusion

This project helped me understand how a complete infrastructure workflow can be built step by step.

It connected web development, automation, virtualization, monitoring, payment flow and system administration into one practical project.

The most important lesson is that making something work is only the first step. A good project also needs documentation, security, monitoring, backup strategy and clear operational limits.
