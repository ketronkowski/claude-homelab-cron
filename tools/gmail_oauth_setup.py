#!/usr/bin/env python3
"""
One-time script to obtain a Gmail API refresh token for the family Gmail account.

Prerequisites:
  pip install google-auth-oauthlib

Usage:
  1. Go to https://console.cloud.google.com
  2. Create a project, enable Gmail API, create an OAuth 2.0 Desktop client
  3. Download client_secret.json and place it next to this script
  4. Run: python3 gmail_oauth_setup.py
  5. Complete the browser consent flow for the FAMILY Gmail account
  6. Copy the printed refresh_token into Bitwarden SM as homelab-cron/gmail-refresh-token
"""

import json
from google_auth_oauthlib.flow import InstalledAppFlow

SCOPES = ["https://www.googleapis.com/auth/gmail.send"]

flow = InstalledAppFlow.from_client_secrets_file("client_secret.json", SCOPES)
creds = flow.run_local_server(port=0)

print("\n--- Store these values in Bitwarden SM under the homelab project ---")
print(f"homelab-cron/gmail-client-id:      {creds.client_id}")
print(f"homelab-cron/gmail-client-secret:  {creds.client_secret}")
print(f"homelab-cron/gmail-refresh-token:  {creds.refresh_token}")
print("---------------------------------------------------------------------\n")
