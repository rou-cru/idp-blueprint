#!/usr/bin/env bash
set -euo pipefail

# Vault secret generator - Production-ready utility
# Generates or stores provided passwords in Vault KV engine
# Requires: htpasswd (from apacheHttpd package) for bcrypt hashing
#
# Usage:
#   ./vault-generate.sh <vault-path> <key-name> [password] [format] [hashing]
#
# Examples:
#   # Generate random password with bcrypt hashing
#   ./vault-generate.sh secret/argocd/admin admin.password "" base64 bcrypt
#
#   # Use provided password without hashing
#   ./vault-generate.sh secret/grafana/admin password "MySecurePass123" base64 none

# shellcheck disable=SC2155
readonly SCRIPT_NAME=$(basename "$0")

log() {
  echo "$*" >&2
}

error() {
  log "ERROR: $*"
  exit 1
}

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME <vault-path> <key-name> [password] [format] [hashing]

Arguments:
  vault-path    Vault KV path where secret will be stored (e.g., secret/argocd/admin)
  key-name      The key name to store the secret under in Vault (e.g., password, admin.password)
  password      Password to store (if empty, generates random 32-byte password)
  format        Output format for random generation: base64 or hex (default: base64)
  hashing       Hashing method: bcrypt or none (default: none)

Environment Variables:
  VAULT_NAMESPACE     Kubernetes namespace where Vault runs (default: auto-detect)
  VAULT_POD           Vault pod name (default: auto-detect)

Examples:
  # Random password with bcrypt
  $SCRIPT_NAME secret/argocd/admin admin.password "" base64 bcrypt

  # Provided password, no hashing
  $SCRIPT_NAME secret/grafana/admin password "MyPass123" base64 none

EOF
  exit 1
}

detect_vault_namespace() {
  local namespace
  namespace=$(kubectl get pods --all-namespaces -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.namespace}' 2>/dev/null || echo "")

  if [[ -z "$namespace" ]]; then
    error "Cannot auto-detect Vault namespace. Set VAULT_NAMESPACE environment variable."
  fi
  echo "$namespace"
}

detect_vault_pod() {
  local namespace=$1
  local pod
  pod=$(kubectl get pods -n "$namespace" -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

  if [[ -z "$pod" ]]; then
    error "Cannot find Vault pod in namespace: ${namespace}. Set VAULT_POD environment variable."
  fi

  echo "$pod"
}

validate_vault_connection() {
  local namespace=$1
  local pod=$2

  if ! kubectl get pod "$pod" -n "$namespace" &>/dev/null; then
    error "Vault pod '$pod' not found in namespace '$namespace'"
  fi

  local pod_status
  pod_status=$(kubectl get pod "$pod" -n "$namespace" -o jsonpath='{.status.phase}')

  if [[ "$pod_status" != "Running" ]]; then
    error "Vault pod '$pod' is not Running (current status: ${pod_status})"
  fi

  if ! kubectl exec -n "$namespace" "$pod" -- vault status &>/dev/null; then
    error "Cannot connect to Vault API in pod '$pod'"
  fi
}

retrieve_vault_token() {
  local namespace=$1
  local token
  token=$(kubectl get secret vault-init-keys -n "$namespace" -o jsonpath='{.data.root-token}' 2>/dev/null | base64 -d)

  if [[ -z "$token" ]]; then
    error "Cannot retrieve Vault token from secret 'vault-init-keys' in namespace '${namespace}'. Has Vault been initialized?"
  fi

  echo "$token"
}

validate_vault_token() {
  local namespace=$1
  local pod=$2
  local token=$3

  if ! kubectl exec -n "$namespace" "$pod" -- \
    env VAULT_TOKEN="$token" \
    vault token lookup &>/dev/null; then
    error "Invalid VAULT_TOKEN or token has expired"
  fi
}

generate_random_password() {
  local namespace=$1
  local pod=$2
  local token=$3
  local length=$4
  local format=$5

  local password
  password=$(kubectl exec -n "$namespace" "$pod" -- \
    env VAULT_TOKEN="$token" \
    vault write -field=random_bytes "sys/tools/random/${length}" "format=${format}" 2>/dev/null | \
    tr -d '\n\r')

  if [[ -z "$password" ]]; then
    error "Failed to generate password from Vault"
  fi

  echo "$password"
}

hash_password() {
    local password=$1
    local hashing_method=$2

    if [[ "$hashing_method" == "bcrypt" ]]; then
        if ! command -v htpasswd &> /dev/null; then
            error "htpasswd could not be found. Please ensure apacheHttpd is installed via devbox."
        fi
        local hashed_password
        if ! hashed_password=$(htpasswd -nbBC 10 admin "$password" 2>/dev/null | head -1 | cut -d: -f2); then
            error "Failed to hash password with htpasswd"
        fi
        if [[ -z "$hashed_password" ]]; then
            error "Failed to hash password with htpasswd - empty result"
        fi
        echo "$hashed_password"
    else
        echo "$password"
    fi
}

store_password_in_vault() {
  local namespace=$1
  local pod=$2
  local token=$3
  local vault_path=$4
  local key_name=$5
  local password_to_store=$6

  # Strategy: Try 'patch' first (to preserve existing keys), fallback to 'put' if secret doesn't exist
  # - If secret exists: patch adds/updates only this key, preserving other keys
  # - If secret doesn't exist: patch fails, then we use 'put' to create it
  # This allows secrets like secret/docker/registry to have registry, username, password

  # Try patch first (preserves other keys if secret exists)
  if kubectl exec -n "$namespace" "$pod" -- \
    env VAULT_TOKEN="$token" \
    vault kv patch "$vault_path" "${key_name}=${password_to_store}" &>/dev/null; then
    return 0
  fi

  # If patch failed (likely because secret doesn't exist), use put to create it
  if ! kubectl exec -n "$namespace" "$pod" -- \
    env VAULT_TOKEN="$token" \
    vault kv put "$vault_path" "${key_name}=${password_to_store}" &>/dev/null; then
    error "Failed to store password in Vault at path: ${vault_path}"
  fi
}

verify_storage() {
  local namespace=$1
  local pod=$2
  local token=$3
  local vault_path=$4
  local key_name=$5

  local retrieved_password
  retrieved_password=$(kubectl exec -n "$namespace" "$pod" -- \
    env VAULT_TOKEN="$token" \
    vault kv get -field="$key_name" "$vault_path" 2>/dev/null | tr -d '\n\r')

  if [[ -z "$retrieved_password" ]]; then
    error "Failed to verify password storage at path: ${vault_path}"
  fi
}

main() {
  # Parse arguments
  if [[ $# -lt 2 ]]; then
    usage
  fi

  local vault_path=$1
  local key_name=$2
  local provided_password=${3:-}
  local format=${4:-base64}
  local hashing=${5:-none}

  # Validate format
  if [[ "$format" != "base64" && "$format" != "hex" ]]; then
    error "Invalid format: ${format}. Must be 'base64' or 'hex'"
  fi

  # Validate hashing
  if [[ "$hashing" != "bcrypt" && "$hashing" != "none" ]]; then
    error "Invalid hashing method: ${hashing}. Must be 'bcrypt' or 'none'"
  fi

  # Auto-detect or use environment variables
  local vault_namespace="${VAULT_NAMESPACE:-}"
  local vault_pod="${VAULT_POD:-}"

  if [[ -z "$vault_namespace" ]]; then
    vault_namespace=$(detect_vault_namespace)
  fi

  if [[ -z "$vault_pod" ]]; then
    vault_pod=$(detect_vault_pod "$vault_namespace")
  fi

  local password_source="provided"
  if [[ -z "$provided_password" ]]; then
    password_source="random (32 bytes)"
  fi

  log "Vault path:   ${vault_path}"
  log "Key name:     ${key_name}"
  log "Password:     ${password_source}"
  log "Hashing:      ${hashing}"

  # Preflight checks
  validate_vault_connection "$vault_namespace" "$vault_pod"

  # Retrieve token from K8s secret
  local vault_token
  vault_token=$(retrieve_vault_token "$vault_namespace")

  # Validate token
  validate_vault_token "$vault_namespace" "$vault_pod" "$vault_token"

  # Get password (provided or generate random)
  local password
  if [[ -n "$provided_password" ]]; then
    password="$provided_password"
  else
    password=$(generate_random_password "$vault_namespace" "$vault_pod" "$vault_token" "32" "$format")
  fi

  # Hash password if requested
  local final_password
  final_password=$(hash_password "$password" "$hashing")

  # Store in Vault
  store_password_in_vault "$vault_namespace" "$vault_pod" "$vault_token" "$vault_path" "$key_name" "$final_password"

  # Verify
  verify_storage "$vault_namespace" "$vault_pod" "$vault_token" "$vault_path" "$key_name"

  log "Secret stored: ${vault_path}"
}

main "$@"
