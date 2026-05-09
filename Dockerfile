FROM node:22-slim

ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    jq \
    python3 \
    python3-pip \
    python3-venv \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Python deps in venv to avoid externally-managed-environment error
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir \
    google-auth \
    google-auth-httplib2 \
    google-api-python-client

# kubectl
RUN KUBECTL_VERSION=$(curl -sSL https://dl.k8s.io/release/stable.txt) && \
    curl -sSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" \
    -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# argocd CLI (used as fallback; primary health data via kubectl CRD reads)
RUN curl -sSL "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-${TARGETARCH}" \
    -o /usr/local/bin/argocd && \
    chmod +x /usr/local/bin/argocd

# Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

COPY tasks/ /tasks/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV TASK_PROMPT=/tasks/homelab-health/prompt.txt

ENTRYPOINT ["/entrypoint.sh"]
