# Security Design

This document explains the main security decisions used in the Proxmox Discord Bot Hosting Platform.

The project is a homelab / private beta platform, but security was still considered during the design.

## 1. Portfolio repository without secrets

This GitHub repository is a portfolio and documentation version of the project.

It intentionally excludes:

- Discord bot tokens
- Stripe secret keys
- Stripe webhook secrets
- admin passwords
- Flask secret keys
- production SQLite databases
- private backups
- internal URLs
- private IP addresses
- customer data

Instead, example configuration files are provided.

## 2. Environment variables

Sensitive values are loaded from environment variables or environment files.

Examples:

- ADMIN_PASSWORD
- SECRET_KEY
- BETA_ACCESS_CODE
- STRIPE_SECRET_KEY
- STRIPE_WEBHOOK_SECRET
- STRIPE_PRICE_BASIC
- STRIPE_PRICE_PLUS
- STRIPE_PRICE_PRO

This avoids hardcoding secrets directly inside the source code.

## 3. Example environment file

The repository includes an example environment file.

It shows which variables are required without exposing real values.

Example:

```text
ADMIN_PASSWORD=change-me
SECRET_KEY=change-me
BETA_ACCESS_CODE=change-me
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
```

This helps make the project understandable without leaking secrets.

## 4. Private beta access code

The public order form requires a private beta access code.

This reduces the risk of random visitors creating fake orders, validating tokens or starting payment flows.

The beta code is not a complete security system, but it is useful for a private test phase.

## 5. Admin dashboard protection

The admin dashboard is protected by an admin password.

Admin-only actions include:

- payment simulation
- order cancellation
- order hiding
- bot start
- bot stop
- bot restart
- bot deletion

These actions are not exposed directly to unauthenticated users.

## 6. Discord bot token handling

Discord bot tokens are sensitive.

The project validates the token before provisioning, but the token should not be displayed publicly.

Important rules:

- tokens should not be shown in screenshots
- tokens should not be committed to GitHub
- tokens should not be printed in logs
- tokens should be masked in the admin interface
- token storage should be improved in future versions

Future improvement:

- stronger encryption at rest for stored tokens
- more detailed validation before provisioning
- manual review before accepting unknown bots

## 7. Stripe Checkout

Stripe Checkout handles the payment page.

The application does not store card details.

This reduces the security risk because payment information is handled by Stripe.

## 8. Stripe webhook validation

Stripe webhooks are used to automate subscription lifecycle events.

Examples:

- payment success
- subscription cancellation
- failed payment

Webhook requests must be validated using the Stripe webhook secret.

This prevents fake external requests from triggering provisioning or suspension actions.

## 9. Separation between Flask and Proxmox actions

The Flask web panel does not directly execute Proxmox commands.

Instead:

- Flask handles the web interface and order logic
- SQLite stores the order state
- queue files or actions are created
- Bash workers on the Proxmox host execute infrastructure actions

This design reduces the risk of exposing direct system-level actions through the web panel.

## 10. LXC isolation

Each Discord bot runs in its own LXC container.

This provides basic isolation between bots.

Advantages:

- one bot per container
- resource limits per plan
- independent start / stop / restart
- easier deletion
- easier monitoring

Future improvement:

- review unprivileged container usage
- harden container permissions
- limit network exposure
- add stronger runtime restrictions if needed

## 11. Rate limiting

A simple rate limit is used on the public order endpoint.

This helps reduce spam attempts against:

- order creation
- beta code guessing
- token validation
- repeated form submissions

Future improvement:

- stronger IP-based rate limiting
- reverse proxy rate limiting
- logging suspicious attempts

## 12. Monitoring visibility

Prometheus and Grafana are used for internal monitoring.

The monitoring system is not intended to be public.

Screenshots for GitHub or LinkedIn should be redacted.

Information to hide:

- private IP addresses
- internal URLs
- usernames
- avatars
- tokens
- customer data

## 13. Database security

SQLite is used for the current private beta.

This is simple and sufficient for a homelab portfolio project.

However, the production database should not be committed to GitHub.

Before publishing screenshots or exports, sensitive values must be removed.

Future improvement:

- database backups
- token encryption
- migration to a more robust database if needed
- access control for customer-facing pages

## 14. Backups

Backups are important before changes.

The project uses a backup/versioning workflow to preserve known working states.

Backups should not be published publicly if they contain:

- secrets
- databases
- internal configuration
- tokens
- customer data

## 15. Current limitations

This project is not presented as production-ready.

Current limitations include:

- no high availability
- no guaranteed SLA
- dependency on home internet
- dependency on home electricity
- limited disaster recovery automation
- token encryption can be improved
- customer dashboard is not fully implemented

## 16. Security principles followed

The project follows these principles:

- do not commit secrets
- separate web logic from host-level actions
- validate external webhooks
- protect admin actions
- avoid exposing internal services
- redact screenshots before publishing
- backup before major changes
- document known limitations honestly

## Conclusion

The goal of this security design is not to claim that the platform is production-ready.

The goal is to show that security was considered during the design and that the project has clear operational limits.

For a homelab portfolio project, the most important security choices are:

- keeping secrets out of GitHub
- protecting admin actions
- validating Stripe webhooks
- separating Flask from Proxmox execution
- documenting limitations clearly
