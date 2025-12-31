#!/usr/bin/env bash
# Create k3d cluster with optional private registry authentication
# Usage: k3d-create-cluster.sh <cluster-name> <k3d-config-file> [registry-template-file]

set -euo pipefail

# Arguments
CLUSTER_NAME="${1:?Error: cluster name required}"
K3D_CONFIG="${2:?Error: k3d config file required}"
REGISTRY_TEMPLATE="${3:-}"

# Environment variables (expected from caller)
DOCKER_REGISTRY_URL="${DOCKER_REGISTRY_URL:-}"
DOCKER_REGISTRY_USERNAME="${DOCKER_REGISTRY_USERNAME:-}"
DOCKER_REGISTRY_PASSWORD="${DOCKER_REGISTRY_PASSWORD:-}"

# Validate k3d config exists
if [ ! -f "$K3D_CONFIG" ]; then
  echo "❌ Error: k3d config file not found: $K3D_CONFIG" >&2
  exit 1
fi

# Create temporary file for rendered k3d config
TMP_CFG=$(mktemp)
trap 'rm -f "$TMP_CFG"' EXIT

# Render k3d config with environment variables
envsubst < "$K3D_CONFIG" > "$TMP_CFG"

# Create k3d cluster with optional registry authentication
echo "Creating k3d cluster: $CLUSTER_NAME"

if [ -n "$DOCKER_REGISTRY_URL" ] && [ -n "$DOCKER_REGISTRY_USERNAME" ] && [ -n "$DOCKER_REGISTRY_PASSWORD" ]; then
  # Credentials provided - configure registry authentication
  if [ -z "$REGISTRY_TEMPLATE" ]; then
    echo "⚠️  Warning: Registry credentials provided but no template file specified" >&2
    echo "    Creating cluster without registry authentication" >&2
    k3d cluster create "$CLUSTER_NAME" -c "$TMP_CFG"
  elif [ ! -f "$REGISTRY_TEMPLATE" ]; then
    echo "❌ Error: Registry template file not found: $REGISTRY_TEMPLATE" >&2
    exit 1
  else
    # Render registry config and create cluster with authentication
    TMP_REG=$(mktemp)
    trap 'rm -f "$TMP_CFG" "$TMP_REG"' EXIT

    envsubst < "$REGISTRY_TEMPLATE" > "$TMP_REG"
    echo "✓ Registry authentication configured for: $DOCKER_REGISTRY_URL"

    k3d cluster create "$CLUSTER_NAME" -c "$TMP_CFG" --registry-config "$TMP_REG"
  fi
else
  # No credentials - create cluster without registry authentication
  k3d cluster create "$CLUSTER_NAME" -c "$TMP_CFG"
fi

echo "✓ Cluster created successfully: $CLUSTER_NAME"
