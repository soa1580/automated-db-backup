#!/usr/bin/env python3

import os
import subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer

BACKUP_DIR = "/app/backups"
CONTAINER_NAME = "postgres-db"
DB_NAME = "companydb"


def get_metric_data():
    metrics = []

        # PostgreSQL container status
    # The exporter checks database accessibility directly.
    result = subprocess.run(
        [
            "python",
            "-c",
            (
                "import socket; "
                "s=socket.create_connection(('postgres-db',5432),2); "
                "s.close()"
            )
        ],
        capture_output=True
    )

    postgres_up = 1 if result.returncode == 0 else 0

    metrics.append(
        f'postgres_container_up{{container="{CONTAINER_NAME}"}} {postgres_up}'
    )

    # Backup count
    backups = [
        f for f in os.listdir(BACKUP_DIR)
        if f.startswith(f"{DB_NAME}_") and f.endswith(".sql")
    ]

    metrics.append(f"backup_count {len(backups)}")

    # Latest backup information
    if backups:
        latest = max(
            backups,
            key=lambda f: os.path.getmtime(os.path.join(BACKUP_DIR, f))
        )

        latest_path = os.path.join(BACKUP_DIR, latest)
        size = os.path.getsize(latest_path)
        age = int(__import__("time").time() - os.path.getmtime(latest_path))

        metrics.append(f"latest_backup_size_bytes {size}")
        metrics.append(f"latest_backup_age_seconds {age}")
        metrics.append("backup_available 1")
    else:
        metrics.append("latest_backup_size_bytes 0")
        metrics.append("latest_backup_age_seconds 0")
        metrics.append("backup_available 0")

    return "\n".join(metrics) + "\n"


class MetricsHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        if self.path == "/metrics":
            data = get_metric_data().encode()

            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        return


if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", 8000), MetricsHandler)

    print("Backup metrics exporter running on port 8000")

    server.serve_forever()
