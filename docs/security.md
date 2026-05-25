# Security Notes

This project is a homelab/private beta platform. It is not presented as a production-ready commercial hosting service.

## Secrets Management

Production secrets are intentionally excluded from this repository.

The following files and values must never be committed:

- Discord bot tokens
- Stripe secret keys
- Stripe webhook secrets
- admin passwords
- Flask secret keys
- beta access codes
- production SQLite databases
- internal backup archives
- private IP addresses and internal URLs
- customer data

A sanitized environment example is provided in:

`examples/bot-panel.env.example`

## Admin Protection

The admin dashboard is protected by an admin password loaded from an environment file.

Admin-only actions include:

- payment simulation
- order cancellation
- order hiding
- bot start
- bot stop
- bot restart
- bot deletion

These actions are not exposed directly to unauthenticated users.

## Beta Access Code

The public order form requires a private beta access code.

This prevents random visitors from creating orders, validating Discord tokens, or starting payment flows.

## Rate Limiting

A simple in-memory rate limiter is used on the public order endpoint.

It helps reduce spam attempts against:

- beta code validation
- Discord token validation
- order creation

## Stripe Webhooks

Stripe webhook events are validated using a webhook signing secret.

Webhook handling is used to automate subscription lifecycle actions such as provisioning and suspension.

## Token Handling

Discord bot tokens are required to run customer bots.

The current implementation masks tokens in the admin interface and avoids displaying full tokens publicly.

Future improvement:

- encrypt bot tokens at rest
- rotate or revalidate tokens when needed
- improve token storage separation

## Container Safety

Bots run inside dedicated LXC containers.

The platform supports lifecycle actions:

- start
- stop
- restart
- delete

Subscription cancellation stops or suspends the bot container but does not automatically delete it.

Deletion remains a manual admin action.

## Monitoring Exposure

Prometheus and Grafana are used for internal/admin monitoring.

Customer-facing monitoring is not implemented yet.

Future improvement:

- per-client dashboards
- restricted access
- filtered metrics per customer
