#!/usr/bin/env python3
"""
Generic Ollama runner for tasks that produce file output without tool use.
Reads the full prompt from stdin, calls Ollama's OpenAI-compatible API,
extracts the HTML report, writes it to disk, and sends it via send_email.py.
"""
import os
import re
import subprocess
import sys

from openai import OpenAI


def extract_html(content: str) -> str:
    # Strip markdown code fences if present
    fence = re.search(r"```html\s*(.*?)```", content, re.DOTALL)
    if fence:
        return fence.group(1).strip()
    # Find bare HTML block
    start = re.search(r"<!DOCTYPE html>", content, re.IGNORECASE)
    end = re.search(r"</html>", content, re.IGNORECASE)
    if start and end:
        return content[start.start() : end.end()]
    return content  # fall back to raw content


def main() -> None:
    prompt = sys.stdin.read()

    base_url = os.environ.get("OLLAMA_BASE_URL", "http://localhost:11434/v1")
    model = os.environ.get("OLLAMA_MODEL", "gemma3:4b")
    report_path = os.environ.get("REPORT_PATH", "/tmp/report.html")
    send_script = os.environ.get("SEND_SCRIPT", "/tasks/homelab-health/send_email.py")

    print(f"Calling Ollama at {base_url} model={model}", flush=True)

    client = OpenAI(base_url=base_url, api_key="ollama")
    response = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        temperature=0.1,
    )

    html = extract_html(response.choices[0].message.content)

    with open(report_path, "w") as f:
        f.write(html)
    print(f"Report written to {report_path} ({len(html)} bytes)", flush=True)

    subprocess.run(["python3", send_script, report_path], check=True)


if __name__ == "__main__":
    main()
