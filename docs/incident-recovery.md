# Incident Recovery

This document describes common failure scenarios and recovery steps for the Proxmox Discord Bot Hosting Platform.

The goal is to document how the platform can be checked and recovered when something does not behave as expected.

This is a homelab / private beta project, so the procedures are intentionally simple and practical.

## 1. Order stuck in queued state

### Symptoms

An order is visible in the admin dashboard but remains stuck in the queued state.

The bot container is not created or not started.

### Possible causes

- the provisioning worker is not running
- the job file was not processed
- Proxmox clone failed
- storage issue
- template container unavailable
- database was not synchronized after provisioning

### Checks

Check the worker service:

```bash
systemctl status bot-worker --no-pager -l
```

Check worker logs:

```bash
journalctl -u bot-worker -n 100 --no-pager
```

Check pending jobs:

```bash
ls -lah /var/lib/bot-queue/pending
```

Check Proxmox containers:

```bash
pct list
```

### Recovery

- restart the worker if it is stopped
- check if the CT already exists
- run the sync script
- update the order manually only if necessary
- keep a backup before manual database changes

## 2. Container exists but database is not updated

### Symptoms

A new LXC container exists in Proxmox, but the admin panel still shows no CTID, no IP or an incorrect status.

### Possible causes

- provisioning succeeded but sync failed
- worker stopped after CT creation
- network/IP detection failed
- database update failed

### Checks

List containers:

```bash
pct list
```

Check a container configuration:

```bash
pct config <CTID>
```

Check container IP:

```bash
pct exec <CTID> -- hostname -I
```

Check the SQLite database:

```bash
sqlite3 -header -column /opt/bot-panel/orders.db "SELECT id, bot_name, status, ctid, ct_status, bot_ip FROM orders ORDER BY id DESC LIMIT 10;"
```

### Recovery

Run the synchronization script if available.

The goal is to make the database match the real Proxmox state.

## 3. Bot container is running but Grafana shows no data

### Symptoms

The bot container is running, but Grafana does not display CPU, RAM or disk metrics.

### Possible causes

- Node Exporter is not running inside the container
- Prometheus target file was not regenerated
- Prometheus cannot reach the container IP
- Grafana dashboard variables are incorrect
- wrong Prometheus job selected

### Checks

Check Node Exporter inside the bot container:

```bash
pct exec <CTID> -- systemctl status node_exporter --no-pager -l
```

Check the Prometheus dynamic target file:

```bash
cat /etc/prometheus/file_sd/bots.json
```

Check Prometheus target API:

```bash
curl -s "http://PROMETHEUS_IP:9090/api/v1/targets"
```

Check the bot up metric:

```bash
curl -s "http://PROMETHEUS_IP:9090/api/v1/query?query=up%7Btype%3D%22bot%22%7D"
```

### Recovery

- restart Node Exporter in the bot container
- regenerate the Prometheus bots.json file
- verify Prometheus can scrape the target
- select the correct job and instance in Grafana

## 4. Stripe webhook does not trigger the expected action

### Symptoms

A payment or subscription change occurs in Stripe, but the platform does not update the order status or create/suspend a bot.

### Possible causes

- webhook endpoint unavailable
- webhook secret mismatch
- Stripe event not handled by the application
- application logs contain an error
- Flask/Gunicorn service stopped

### Checks

Check the panel service:

```bash
systemctl status bot-panel --no-pager -l
```

Check panel logs:

```bash
journalctl -u bot-panel -n 100 --no-pager
```

Check Stripe dashboard webhook delivery logs.

Check the order status in the database.

### Recovery

- fix webhook secret or endpoint configuration
- restart the panel service
- replay the Stripe webhook from Stripe dashboard if needed
- manually simulate payment only in test/beta context

## 5. Bot must be stopped or suspended

### Symptoms

A bot must be suspended because a subscription was cancelled, a test ended or the bot should no longer run.

### Expected behavior

The platform should stop the LXC container without deleting it immediately.

This allows recovery or manual inspection if needed.

### Checks

Check container status:

```bash
pct status <CTID>
```

Stop the container:

```bash
pct stop <CTID>
```

Verify status:

```bash
pct status <CTID>
```

### Recovery

If the admin dashboard action fails, stop the container manually and synchronize the database.

## 6. Bot must be deleted

### Symptoms

A bot container must be permanently removed.

### Important note

Deletion should be manual or admin-confirmed.

The platform should not automatically delete containers immediately after subscription cancellation.

### Checks

Verify the CTID:

```bash
pct list
```

Stop the container:

```bash
pct stop <CTID>
```

Destroy the container:

```bash
pct destroy <CTID>
```

Regenerate Prometheus targets:

```bash
./generate-bots-sd.sh
```

Synchronize orders:

```bash
./sync-bot-orders.sh
```

## 7. Server reboot or power outage

### Symptoms

After a reboot or power outage, some services or containers may not restart automatically.

### Possible causes

- CT onboot not enabled
- systemd service not enabled
- worker not running
- Prometheus/Grafana not running
- bot containers not started

### Checks

Check containers:

```bash
pct list
```

Check onboot configuration:

```bash
pct config <CTID> | grep onboot
```

Check services:

```bash
systemctl is-enabled bot-worker
systemctl is-enabled bot-action-worker
```

Inside service containers:

```bash
systemctl status prometheus --no-pager -l
systemctl status grafana-server --no-pager -l
```

### Recovery

- start stopped containers
- enable onboot for important containers
- enable systemd services
- check monitoring after recovery

## 8. Prometheus dynamic discovery file is empty

### Symptoms

The Prometheus bots.json file contains an empty list even though bot containers exist.

### Possible causes

- no active/running bots found by the generation script
- bot metadata missing
- container IP detection failed
- script was run before bot fully started

### Checks

```bash
cat /etc/prometheus/file_sd/bots.json
pct list
```

Check bot metadata files if used by the project.

### Recovery

- wait until the bot has an IP address
- regenerate bots.json
- check Prometheus targets again

## 9. Database cleanup

### Symptoms

Old hidden or deleted orders remain visible in the database or admin panel.

### Recovery

The database can be cleaned after confirming that the corresponding containers are removed or no longer needed.

A backup should be created before deleting records.

Example:

```bash
cp /opt/bot-panel/orders.db /opt/bot-panel/orders.db.backup
```

Then clean only confirmed obsolete records.

## 10. General recovery principles

General rules used in this project:

- create a backup before manual changes
- check the real Proxmox state before editing the database
- do not delete containers automatically without confirmation
- keep logs for troubleshooting
- prefer synchronization scripts over manual edits
- document every important change
- do not expose secrets in logs or screenshots

## Conclusion

Incident recovery is an important part of system administration.

This project helped me understand that building a service is not only about creating features. It is also about knowing how to diagnose problems, recover from failures, keep state consistent and document operational procedures.
