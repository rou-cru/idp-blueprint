# Use Jenkins inbound agent image for Kubernetes-based agents
FROM jenkins/inbound-agent:latest-jdk21

USER root

# Install system dependencies and CLI tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        git \
        jq \
        unzip \
        tar \
        gzip \
        shellcheck \
        gnupg \
        lsb-release \
        && rm -rf /var/lib/apt/lists/*

# Install kubectl
ARG KUBECTL_VERSION=v1.31.4
RUN curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && install -o jenkins -g jenkins -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# Install kustomize
ARG KUSTOMIZE_VERSION=v5.4.2
RUN curl -LO "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" \
    && tar -xzf kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz \
    && install -o jenkins -g jenkins -m 0755 kustomize /usr/local/bin/kustomize \
    && rm kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz kustomize

# Install Helm
ARG HELM_VERSION=v3.16.3
RUN curl -LO "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" \
    && tar -xzf helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && install -o jenkins -g jenkins -m 0755 linux-amd64/helm /usr/local/bin/helm \
    && rm -rf helm-${HELM_VERSION}-linux-amd64.tar.gz linux-amd64

# Install OpenTofu
ARG TOFU_VERSION=1.8.3
RUN curl -LO "https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_linux_amd64.tar.gz" \
    && tar -xzf tofu_${TOFU_VERSION}_linux_amd64.tar.gz \
    && install -o jenkins -g jenkins -m 0755 tofu /usr/local/bin/tofu \
    && rm tofu_${TOFU_VERSION}_linux_amd64.tar.gz tofu

# Install Checkov (security scanner for IaC)
RUN curl -L --output checkov https://github.com/bridgecrewio/checkov/releases/latest/download/checkov_linux_64 \
    && install -o jenkins -g jenkins -m 0755 checkov /usr/local/bin/checkov \
    && rm checkov

# Install TruffleHog (secret scanner)
RUN curl -L --output trufflehog https://github.com/trufflesecurity/trufflehog/releases/latest/download/trufflehog_linux_amd64 \
    && install -o jenkins -g jenkins -m 0755 trufflehog /usr/local/bin/trufflehog \
    && rm trufflehog

# Install kubeval (Kubernetes manifest validator)
RUN curl -L https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz | tar xz \
    && install -o jenkins -g jenkins -m 0755 kubeval /usr/local/bin/kubeval \
    && rm kubeval

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh && rm -rf /var/lib/apt/lists/*

# Switch back to jenkins user
USER jenkins

# Set working directory
WORKDIR /home/jenkins/agent
