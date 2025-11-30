#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="config.toml"
OUTPUT_FORMAT="env"

for arg in "$@"; do
    if [ "$arg" = "json" ]; then
        OUTPUT_FORMAT="json"
    else
        CONFIG_FILE="$arg"
    fi
done

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file '$CONFIG_FILE' not found." >&2
    exit 1
fi

# Helper function to get config value
get_conf() {
    ./Scripts/config-get.sh "$1" "$CONFIG_FILE"
}

# --- Images ---
DOCKER_IMAGE_NAME=$(get_conf images.docker_image_name)
DOCKER_IMAGE_TAG=$(get_conf images.docker_image_tag)
DOCKER_IMAGE_TAG_MINIMAL=$(get_conf images.docker_image_tag_minimal)

# --- Network ---
LAN_IP=$(get_conf network.lan_ip)
if [ -z "$LAN_IP" ] || [ "$LAN_IP" = '""' ]; then
    LAN_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || echo "127.0.0.1")
fi
NODEPORT_HTTP=$(get_conf network.nodeport_http)
NODEPORT_HTTPS=$(get_conf network.nodeport_https)

# --- Git ---
REPO_URL=$(get_conf git.repo_url)
if [ -z "$REPO_URL" ] || [ "$REPO_URL" = '""' ] || [ "$REPO_URL" = "''" ]; then
    REPO_URL=$(git config --get remote.origin.url 2>/dev/null || echo "https://github.com/rou-cru/idp-blueprint.git")
fi

TARGET_REVISION=$(get_conf git.target_revision)
if [ -z "$TARGET_REVISION" ] || [ "$TARGET_REVISION" = '""' ] || [ "$TARGET_REVISION" = "''" ]; then
    TARGET_REVISION=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")
fi

GITHUB_ORG=$(get_conf git.github_org)
if [ -z "$GITHUB_ORG" ] || [ "$GITHUB_ORG" = '""' ] || [ "$GITHUB_ORG" = "''" ]; then
    GITHUB_ORG="rou-cru"
fi

GITHUB_REPO=$(get_conf git.github_repo)
if [ -z "$GITHUB_REPO" ] || [ "$GITHUB_REPO" = '""' ] || [ "$GITHUB_REPO" = "''" ]; then
    GITHUB_REPO="idp-blueprint"
fi

GITHUB_BRANCH=$(get_conf git.github_branch)
if [ -z "$GITHUB_BRANCH" ] || [ "$GITHUB_BRANCH" = '""' ] || [ "$GITHUB_BRANCH" = "''" ]; then
    GITHUB_BRANCH="main"
fi

GITHUB_TOKEN=$(get_conf git.github_token)

# --- Versions ---
CILIUM_VERSION=$(get_conf versions.cilium)
CERT_MANAGER_VERSION=$(get_conf versions.cert_manager)
PROMETHEUS_CRDS_VERSION=$(get_conf versions.prometheus_operator_crds)
GATEWAY_API_VERSION=$(get_conf versions.gateway_api)
EXTERNAL_SECRETS_VERSION=$(get_conf versions.external_secrets)
VAULT_VERSION=$(get_conf versions.vault)
ARGOCD_VERSION=$(get_conf versions.argocd)
BACKSTAGE_VERSION=$(get_conf versions.backstage)

# --- Operational ---
KUBECTL_TIMEOUT=$(get_conf operational.kubectl_timeout)
K3D_CONFIG=$(get_conf operational.k3d_config)
REGISTRY_CACHE_PATH=$(get_conf operational.registry_cache_path)

# --- Cluster ---
CLUSTER_NAME=$(get_conf cluster.name)
if [ -z "$CLUSTER_NAME" ] || [ "$CLUSTER_NAME" = '""' ]; then
    CLUSTER_NAME="idp-demo"
fi

# --- ArgoCD ---
ARGOCD_SYNC_TIMEOUT=$(get_conf argocd.sync_timeout)
ARGOCD_BACKOFF_DURATION=$(get_conf argocd.backoff_duration)
ARGOCD_BACKOFF_FACTOR=$(get_conf argocd.backoff_factor)
ARGOCD_BACKOFF_MAX_DURATION=$(get_conf argocd.backoff_max_duration)
ARGOCD_RETRY_LIMIT=$(get_conf argocd.retry_limit)

# --- Gateway ---
GATEWAY_WAIT_TIMEOUT=$(get_conf gateway.wait_timeout)

# --- Passwords ---
ARGOCD_ADMIN_PASSWORD=$(get_conf passwords.argocd_admin)
GRAFANA_ADMIN_PASSWORD=$(get_conf passwords.grafana_admin)
SONARQUBE_ADMIN_PASSWORD=$(get_conf passwords.sonarqube_admin)
SONARQUBE_MONITORING_PASSCODE=$(get_conf passwords.sonarqube_monitoring)
BACKSTAGE_DEX_CLIENT_SECRET=$(get_conf passwords.backstage_dex_client)

# --- Registry ---
DOCKER_REGISTRY_URL=$(get_conf registry.url)
DOCKER_REGISTRY_USERNAME=$(get_conf registry.username)
DOCKER_REGISTRY_PASSWORD=$(get_conf registry.password)

# --- Fuses ---
get_fuse() {
    local val
    val=$(get_conf "fuses.$1")
    if [ -z "$val" ]; then echo "$2"; else echo "$val"; fi
}
FUSE_POLICIES=$(get_fuse policies true)
FUSE_SECURITY=$(get_fuse security true)
FUSE_OBSERVABILITY=$(get_fuse observability true)
FUSE_CICD=$(get_fuse cicd true)
FUSE_BACKSTAGE=$(get_fuse backstage true)
FUSE_PROD=$(get_fuse prod false)

# --- Derived ---
DNS_SUFFIX=$(echo "$LAN_IP" | tr '.' '-').nip.io

# --- Output ---
if [ "$OUTPUT_FORMAT" = "json" ]; then
    jq -n \
      --arg CONFIG_FILE "$CONFIG_FILE" \
      --arg DOCKER_IMAGE_NAME "$DOCKER_IMAGE_NAME" \
      --arg DOCKER_IMAGE_TAG "$DOCKER_IMAGE_TAG" \
      --arg DOCKER_IMAGE_TAG_MINIMAL "$DOCKER_IMAGE_TAG_MINIMAL" \
      --arg LAN_IP "$LAN_IP" \
      --arg NODEPORT_HTTP "$NODEPORT_HTTP" \
      --arg NODEPORT_HTTPS "$NODEPORT_HTTPS" \
      --arg REPO_URL "$REPO_URL" \
      --arg TARGET_REVISION "$TARGET_REVISION" \
      --arg GITHUB_TOKEN "$GITHUB_TOKEN" \
      --arg CILIUM_VERSION "$CILIUM_VERSION" \
      --arg CERT_MANAGER_VERSION "$CERT_MANAGER_VERSION" \
      --arg PROMETHEUS_CRDS_VERSION "$PROMETHEUS_CRDS_VERSION" \
      --arg GATEWAY_API_VERSION "$GATEWAY_API_VERSION" \
      --arg EXTERNAL_SECRETS_VERSION "$EXTERNAL_SECRETS_VERSION" \
      --arg VAULT_VERSION "$VAULT_VERSION" \
      --arg ARGOCD_VERSION "$ARGOCD_VERSION" \
      --arg BACKSTAGE_VERSION "$BACKSTAGE_VERSION" \
      --arg KUBECTL_TIMEOUT "$KUBECTL_TIMEOUT" \
      --arg K3D_CONFIG "$K3D_CONFIG" \
      --arg REGISTRY_CACHE_PATH "$REGISTRY_CACHE_PATH" \
      --arg CLUSTER_NAME "$CLUSTER_NAME" \
      --arg ARGOCD_SYNC_TIMEOUT "$ARGOCD_SYNC_TIMEOUT" \
      --arg ARGOCD_BACKOFF_DURATION "$ARGOCD_BACKOFF_DURATION" \
      --arg ARGOCD_BACKOFF_FACTOR "$ARGOCD_BACKOFF_FACTOR" \
      --arg ARGOCD_BACKOFF_MAX_DURATION "$ARGOCD_BACKOFF_MAX_DURATION" \
      --arg ARGOCD_RETRY_LIMIT "$ARGOCD_RETRY_LIMIT" \
      --arg GATEWAY_WAIT_TIMEOUT "$GATEWAY_WAIT_TIMEOUT" \
      --arg ARGOCD_ADMIN_PASSWORD "$ARGOCD_ADMIN_PASSWORD" \
      --arg GRAFANA_ADMIN_PASSWORD "$GRAFANA_ADMIN_PASSWORD" \
      --arg SONARQUBE_ADMIN_PASSWORD "$SONARQUBE_ADMIN_PASSWORD" \
      --arg SONARQUBE_MONITORING_PASSCODE "$SONARQUBE_MONITORING_PASSCODE" \
      --arg BACKSTAGE_DEX_CLIENT_SECRET "$BACKSTAGE_DEX_CLIENT_SECRET" \
      --arg DOCKER_REGISTRY_URL "$DOCKER_REGISTRY_URL" \
      --arg DOCKER_REGISTRY_USERNAME "$DOCKER_REGISTRY_USERNAME" \
      --arg DOCKER_REGISTRY_PASSWORD "$DOCKER_REGISTRY_PASSWORD" \
      --arg FUSE_POLICIES "$FUSE_POLICIES" \
      --arg FUSE_SECURITY "$FUSE_SECURITY" \
      --arg FUSE_OBSERVABILITY "$FUSE_OBSERVABILITY" \
      --arg FUSE_CICD "$FUSE_CICD" \
      --arg FUSE_BACKSTAGE "$FUSE_BACKSTAGE" \
      --arg FUSE_PROD "$FUSE_PROD" \
      --arg DNS_SUFFIX "$DNS_SUFFIX" \
      '$ARGS.named'
else
    echo "# Generated by Scripts/generate-env.sh"
    echo "CONFIG_FILE=$CONFIG_FILE"
    echo "DOCKER_IMAGE_NAME=$DOCKER_IMAGE_NAME"
    echo "DOCKER_IMAGE_TAG=$DOCKER_IMAGE_TAG"
    echo "DOCKER_IMAGE_TAG_MINIMAL=$DOCKER_IMAGE_TAG_MINIMAL"
    echo "LAN_IP=$LAN_IP"
    echo "NODEPORT_HTTP=$NODEPORT_HTTP"
    echo "NODEPORT_HTTPS=$NODEPORT_HTTPS"
    echo "REPO_URL=$REPO_URL"
    echo "TARGET_REVISION=$TARGET_REVISION"
    echo "GITHUB_ORG=$GITHUB_ORG"
    echo "GITHUB_REPO=$GITHUB_REPO"
    echo "GITHUB_BRANCH=$GITHUB_BRANCH"
    echo "GITHUB_TOKEN=$GITHUB_TOKEN"
    echo "CILIUM_VERSION=$CILIUM_VERSION"
    echo "CERT_MANAGER_VERSION=$CERT_MANAGER_VERSION"
    echo "PROMETHEUS_CRDS_VERSION=$PROMETHEUS_CRDS_VERSION"
    echo "GATEWAY_API_VERSION=$GATEWAY_API_VERSION"
    echo "EXTERNAL_SECRETS_VERSION=$EXTERNAL_SECRETS_VERSION"
    echo "VAULT_VERSION=$VAULT_VERSION"
    echo "ARGOCD_VERSION=$ARGOCD_VERSION"
    echo "BACKSTAGE_VERSION=$BACKSTAGE_VERSION"
    echo "KUBECTL_TIMEOUT=$KUBECTL_TIMEOUT"
    echo "K3D_CONFIG=$K3D_CONFIG"
    echo "REGISTRY_CACHE_PATH=$REGISTRY_CACHE_PATH"
    echo "CLUSTER_NAME=$CLUSTER_NAME"
    echo "ARGOCD_SYNC_TIMEOUT=$ARGOCD_SYNC_TIMEOUT"
    echo "ARGOCD_BACKOFF_DURATION=$ARGOCD_BACKOFF_DURATION"
    echo "ARGOCD_BACKOFF_FACTOR=$ARGOCD_BACKOFF_FACTOR"
    echo "ARGOCD_BACKOFF_MAX_DURATION=$ARGOCD_BACKOFF_MAX_DURATION"
    echo "ARGOCD_RETRY_LIMIT=$ARGOCD_RETRY_LIMIT"
    echo "GATEWAY_WAIT_TIMEOUT=$GATEWAY_WAIT_TIMEOUT"
    echo "ARGOCD_ADMIN_PASSWORD=$ARGOCD_ADMIN_PASSWORD"
    echo "GRAFANA_ADMIN_PASSWORD=$GRAFANA_ADMIN_PASSWORD"
    echo "SONARQUBE_ADMIN_PASSWORD=$SONARQUBE_ADMIN_PASSWORD"
    echo "SONARQUBE_MONITORING_PASSCODE=$SONARQUBE_MONITORING_PASSCODE"
    echo "BACKSTAGE_DEX_CLIENT_SECRET=$BACKSTAGE_DEX_CLIENT_SECRET"
    echo "DOCKER_REGISTRY_URL=$DOCKER_REGISTRY_URL"
    echo "DOCKER_REGISTRY_USERNAME=$DOCKER_REGISTRY_USERNAME"
    echo "DOCKER_REGISTRY_PASSWORD=$DOCKER_REGISTRY_PASSWORD"
    echo "FUSE_POLICIES=$FUSE_POLICIES"
    echo "FUSE_SECURITY=$FUSE_SECURITY"
    echo "FUSE_OBSERVABILITY=$FUSE_OBSERVABILITY"
    echo "FUSE_CICD=$FUSE_CICD"
    echo "FUSE_BACKSTAGE=$FUSE_BACKSTAGE"
    echo "FUSE_PROD=$FUSE_PROD"
    echo "DNS_SUFFIX=$DNS_SUFFIX"
fi
