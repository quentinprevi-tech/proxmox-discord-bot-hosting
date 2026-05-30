# Flask Panel Example

This directory contains a sanitized example of the Flask order panel used in the portfolio project.

The goal is to show the application logic without exposing production secrets, real Discord tokens, payment provider credentials or private infrastructure details.

## Files

- app.example.py
  - simplified Flask web panel
  - order creation form
  - admin order review page
  - SQLite storage
  - status workflow example
  - token preview only, no full token storage

- schema.sql
  - SQLite schema used by the example panel

## Example workflow

1. A user submits a bot name, plan and Discord token.
2. The bot name is sanitized.
3. The token is not stored in full. Only a masked preview is stored.
4. The order is created with status pending_validation.
5. An admin can update the order status.
6. In the real lab, approved orders are later handled by host-side worker scripts.

## Running locally

Commands:

python3 -m venv .venv
source .venv/bin/activate
pip install flask
export BOT_PANEL_ADMIN_PASSWORD="change-me"
python app.example.py

Then open:

http://127.0.0.1:5000

## Security notes

This example intentionally avoids:

- real Discord tokens
- real payment provider secrets
- production database files
- private Proxmox credentials
- customer data
