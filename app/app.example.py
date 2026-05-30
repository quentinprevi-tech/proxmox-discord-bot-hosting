"""
Sanitized Flask panel example for the Proxmox Discord Bot Hosting portfolio project.

This example demonstrates the order workflow without exposing secrets:
- no real Discord tokens are stored
- no payment provider credentials are included
- no Proxmox credentials are included
"""

import os
import re
import sqlite3
from pathlib import Path

from flask import Flask, g, redirect, render_template_string, request, url_for

BASE_DIR = Path(__file__).resolve().parent
DATABASE = Path(os.environ.get("BOT_PANEL_DB", BASE_DIR / "orders.db"))
ADMIN_PASSWORD = os.environ.get("BOT_PANEL_ADMIN_PASSWORD", "change-me")

ALLOWED_PLANS = ["basic", "plus", "pro"]

app = Flask(__name__)


def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(DATABASE)
        g.db.row_factory = sqlite3.Row
    return g.db


@app.teardown_appcontext
def close_db(error=None):
    db = g.pop("db", None)
    if db is not None:
        db.close()


def init_db():
    schema = BASE_DIR / "schema.sql"
    get_db().executescript(schema.read_text(encoding="utf-8"))


def sanitize_bot_name(value):
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9_-]+", "-", value)
    value = re.sub(r"-+", "-", value).strip("-")

    if not value:
        raise ValueError("Bot name cannot be empty.")

    if len(value) > 32:
        raise ValueError("Bot name must be 32 characters or less.")

    return value


def token_preview(token):
    token = token.strip()

    if len(token) < 12:
        raise ValueError("Discord token looks too short.")

    return f"{token[:6]}...{token[-4:]}"


def create_order(bot_name, plan, discord_token):
    if plan not in ALLOWED_PLANS:
        raise ValueError("Invalid hosting plan.")

    db = get_db()
    cursor = db.execute(
        """
        INSERT INTO orders (bot_name, plan, discord_token_preview, status)
        VALUES (?, ?, ?, ?)
        """,
        (
            sanitize_bot_name(bot_name),
            plan,
            token_preview(discord_token),
            "pending_validation",
        ),
    )
    db.commit()
    return cursor.lastrowid


def update_order_status(order_id, status):
    allowed_statuses = [
        "pending_validation",
        "token_valid",
        "token_invalid",
        "approved",
        "queued",
        "running",
        "failed",
        "cancelled",
    ]

    if status not in allowed_statuses:
        raise ValueError("Invalid status.")

    db = get_db()
    db.execute(
        "UPDATE orders SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
        (status, order_id),
    )
    db.commit()


@app.route("/", methods=["GET", "POST"])
def index():
    message = None

    if request.method == "POST":
        try:
            order_id = create_order(
                request.form["bot_name"],
                request.form["plan"],
                request.form["discord_token"],
            )
            message = f"Order #{order_id} created and waiting for validation."
        except ValueError as exc:
            message = str(exc)

    return render_template_string(
        """
        <h1>Discord Bot Hosting</h1>

        {% if message %}
            <p><strong>{{ message }}</strong></p>
        {% endif %}

        <form method="post">
            <label>Bot name</label><br>
            <input name="bot_name" required><br><br>

            <label>Plan</label><br>
            <select name="plan">
                <option value="basic">Basic</option>
                <option value="plus">Plus</option>
                <option value="pro">Pro</option>
            </select><br><br>

            <label>Discord token</label><br>
            <input name="discord_token" type="password" required><br><br>

            <button type="submit">Create order</button>
        </form>

        <p><a href="{{ url_for('admin') }}">Admin panel</a></p>
        """,
        message=message,
    )


@app.route("/admin", methods=["GET", "POST"])
def admin():
    if request.method == "POST":
        if request.form.get("password") != ADMIN_PASSWORD:
            return "Unauthorized", 403

        update_order_status(int(request.form["order_id"]), request.form["status"])
        return redirect(url_for("admin"))

    orders = get_db().execute(
        """
        SELECT id, bot_name, plan, discord_token_preview, status, created_at
        FROM orders
        ORDER BY created_at DESC
        """
    ).fetchall()

    return render_template_string(
        """
        <h1>Admin orders</h1>

        <table border="1" cellpadding="6">
            <tr>
                <th>ID</th>
                <th>Bot</th>
                <th>Plan</th>
                <th>Token preview</th>
                <th>Status</th>
                <th>Created</th>
                <th>Update</th>
            </tr>

            {% for order in orders %}
            <tr>
                <td>{{ order.id }}</td>
                <td>{{ order.bot_name }}</td>
                <td>{{ order.plan }}</td>
                <td>{{ order.discord_token_preview }}</td>
                <td>{{ order.status }}</td>
                <td>{{ order.created_at }}</td>
                <td>
                    <form method="post">
                        <input name="password" type="password" placeholder="admin password">
                        <input name="order_id" type="hidden" value="{{ order.id }}">

                        <select name="status">
                            <option value="token_valid">token_valid</option>
                            <option value="token_invalid">token_invalid</option>
                            <option value="approved">approved</option>
                            <option value="queued">queued</option>
                            <option value="running">running</option>
                            <option value="failed">failed</option>
                            <option value="cancelled">cancelled</option>
                        </select>

                        <button type="submit">Update</button>
                    </form>
                </td>
            </tr>
            {% endfor %}
        </table>
        """,
        orders=orders,
    )


@app.cli.command("init-db")
def init_db_command():
    init_db()
    print(f"Initialized database at {DATABASE}")


if __name__ == "__main__":
    with app.app_context():
        init_db()

    app.run(host="127.0.0.1", port=5000, debug=True)
