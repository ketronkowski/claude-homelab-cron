#!/usr/bin/env python3
import sys
import base64
import os
from datetime import datetime, timezone
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build


def send_report(html_path: str) -> None:
    with open(html_path, "r") as f:
        html_content = f.read()

    creds = Credentials(
        token=None,
        refresh_token=os.environ["GMAIL_REFRESH_TOKEN"],
        token_uri="https://oauth2.googleapis.com/token",
        client_id=os.environ["GMAIL_CLIENT_ID"],
        client_secret=os.environ["GMAIL_CLIENT_SECRET"],
    )

    service = build("gmail", "v1", credentials=creds)

    from_addr = os.environ["GMAIL_FROM_ADDRESS"]
    to_addr = "kevin.tronkowski@gmail.com"
    date_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    msg = MIMEMultipart("alternative")
    msg["Subject"] = f"Homelab Health Report — {date_str}"
    msg["From"] = from_addr
    msg["To"] = to_addr
    msg.attach(MIMEText(html_content, "html"))

    raw = base64.urlsafe_b64encode(msg.as_bytes()).decode()
    service.users().messages().send(userId="me", body={"raw": raw}).execute()
    print(f"Report sent from {from_addr} to {to_addr}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: send_email.py <path-to-report.html>", file=sys.stderr)
        sys.exit(1)
    send_report(sys.argv[1])
