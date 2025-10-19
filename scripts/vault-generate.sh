#!/bin/bash
set -euo pipefail

# Vault secret generator - Decoupled, reusable utility
# Generates random passwords using Vault and stores them in KV engine
#
# Usage:
#   ./vault-generate-secret.sh <vault-path> [length] [format] [hashing] [key_name]
#
# Examples:
#   ./vault-generate-secret.sh secret/argocd/admin 32 base64 bcrypt admin.password
#   ./vault-generate-secret.sh secret/jenkins/admin 24 hex none password

# shellcheck disable=SC2155
readonly SCRIPT_NAME=$(basename "$0")

log() {
  echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] $*" >&2
}

error() {
  log "ERROR: $*"
  exit 1
}

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME <vault-path> [length] [format] [hashing] [key_name]

Arguments:
  vault-path    Vault KV path where secret will be stored (e.g., secret/argocd/admin)
  length        Password length in bytes (default: 32)
  format        Output format: base64 or hex (default: base64)
  hashing       Hashing method: bcrypt or none (default: none)
  key_name      The key name to store the secret under in Vault (default: password)

Environment Variables:
  VAULT_NAMESPACE     Kubernetes namespace where Vault runs (default: auto-detect)
  VAULT_POD           Vault pod name (default: auto-detect first vault pod)

Note:
  Token is automatically retrieved from 'vault-init-keys' secret in Vault namespace.
  Ensure Vault has been initialized before running this script.

Examples:
  $SCRIPT_NAME secret/argocd/admin 32 base64 bcrypt admin.password
  $SCRIPT_NAME secret/jenkins/admin 24 hex

EOF
  exit 1
}

detect_vault_namespace() {
  log "Auto-detecting Vault namespace..."
  
  local namespace
  namespace=$(kubectl get pods --all-namespaces -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.namespace}' 2>/dev/null || echo "")
  
  if [[ -z "$namespace" ]]; then
    error "Cannot auto-detect Vault namespace. Set VAULT_NAMESPACE environment variable."
  fi
  
  log "Detected Vault namespace: ${namespace}"
  echo "$namespace"
}

detect_vault_pod() {
  local namespace=$1
  
  log "Auto-detecting Vault pod in namespace: ${namespace}..."
  
  local pod
  pod=$(kubectl get pods -n "$namespace" -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
  
  if [[ -z "$pod" ]]; then
    error "Cannot find Vault pod in namespace: ${namespace}. Set VAULT_POD environment variable."
  fi
  
  log "Detected Vault pod: ${pod}"
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
  
  log "✅ Vault connection validated"
}

retrieve_vault_token() {
  local namespace=$1

  log "Retrieving Vault token from Kubernetes secret..."

  local token
  token=$(kubectl get secret vault-init-keys -n "$namespace" -o jsonpath='{.data.root-token}' 2>/dev/null | base64 -d)

  if [[ -z "$token" ]]; then
    error "Cannot retrieve Vault token from secret 'vault-init-keys' in namespace '${namespace}'. Has Vault been initialized?"
  fi

  log "✅ Token retrieved successfully"
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

  log "✅ Vault token validated"
}

generate_random_password() {
  local namespace=$1
  local pod=$2
  local token=$3
  local length=$4
  local format=$5

  log "Generating ${length}-byte random password using Vault (format: ${format})..."

  local password
  password=$(kubectl exec -n "$namespace" "$pod" -- \
    env VAULT_TOKEN="$token" \
    vault write -field=random_bytes "sys/tools/random/${length}" "format=${format}" 2>/dev/null | \
    tr -d '\n\r')

  if [[ -z "$password" ]]; then
    error "Failed to generate password from Vault"
  fi

  log "✅ Password generated successfully"
  log "[DEBUG] Generated password: ${password}"

  echo "$password"
}

hash_password() {
    local password=$1
    local hashing_method=$2
    
    if [[ "$hashing_method" == "bcrypt" ]]; then
        log "Hashing password with bcrypt..."
        if ! command -v bcrypt-tool &> /dev/null; then
            error "bcrypt-tool could not be found. Please ensure it is installed and in the PATH."
        fi
        local hashed_password
        hashed_password=$(bcrypt-tool hash "$password")
        log "✅ Password hashed successfully"
        log "[DEBUG] Hashed password: ${hashed_password}"
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

  log "Storing password in Vault at path: ${vault_path} with key: ${key_name}..."

  if ! kubectl exec -n "$namespace" "$pod" -- \
    env VAULT_TOKEN="$token" \
    vault kv put "$vault_path" "${key_name}=${password_to_store}" &>/dev/null; then
    error "Failed to store password in Vault at path: ${vault_path}"
  fi

  log "✅ Password stored successfully at ${vault_path}"
}

verify_storage() {
  local namespace=$1
  local pod=$2
  local token=$3
  local vault_path=$4
  local key_name=$5

  log "Verifying storage..."

  local retrieved_password
  retrieved_password=$(kubectl exec -n "$namespace" "$pod" -- \
    env VAULT_TOKEN="$token" \
    vault kv get -field="$key_name" "$vault_path" 2>/dev/null | tr -d '\n\r')

  if [[ -z "$retrieved_password" ]]; then
    error "Failed to verify password storage at path: ${vault_path}"
  fi

  log "✅ Password verified in Vault"
  log "[DEBUG] Retrieved password: ${retrieved_password}"
}

save_plaintext_to_k8s_secret() {
  local vault_path=$1
  local plaintext_password=$2
  local vault_namespace=$3

  # Extract service name from vault path (e.g., secret/argocd/admin -> argocd)
  local service_name
  service_name=$(echo "$vault_path" | cut -d'/' -f2)

  local secret_name="${service_name}-admin-plaintext"

  log "Saving plaintext password to Kubernetes secret '${secret_name}' in namespace '${vault_namespace}'..."

  if kubectl delete secret "$secret_name" -n "$vault_namespace" --ignore-not-found=true &>/dev/null && \
     kubectl create secret generic "$secret_name" -n "$vault_namespace" --from-literal=password="$plaintext_password" &>/dev/null; then
    log "✅ Plaintext password saved to secret: ${vault_namespace}/${secret_name}"
  else
    log "⚠️  Warning: Failed to save plaintext password to Kubernetes secret (non-critical)"
  fi
}

main() {
  # Parse arguments
  if [[ $# -lt 1 ]]; then
    usage
  fi

  local vault_path=$1
  local length=${2:-32}
  local format=${3:-base64}
  local hashing=${4:-none}
  local key_name=${5:-password}

  # Validate format
  if [[ "$format" != "base64" && "$format" != "hex" ]]; then
    error "Invalid format: ${format}. Must be 'base64' or 'hex'"
  fi

  # Validate hashing
  if [[ "$hashing" != "bcrypt" && "$hashing" != "none" ]]; then
    error "Invalid hashing method: ${hashing}. Must be 'bcrypt' or 'none'"
  fi

  # Validate length
  if ! [[ "$length" =~ ^[0-9]+$ ]] || [[ "$length" -lt 16 ]]; then
    error "Invalid length: ${length}. Must be integer >= 16"
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

  log "===================================================="
  log "Vault Secret Generator"
  log "===================================================="
  log "Vault path:   ${vault_path}"
  log "Length:       ${length} bytes"
  log "Format:       ${format}"
  log "Hashing:      ${hashing}"
  log "Key Name:     ${key_name}"
  log "Vault pod:    ${vault_namespace}/${vault_pod}"
  log "===================================================="

  # Preflight checks
  validate_vault_connection "$vault_namespace" "$vault_pod"

  # Retrieve token from K8s secret (created by vault-manual-init.sh)
  local vault_token
  vault_token=$(retrieve_vault_token "$vault_namespace")

  # Validate token
  validate_vault_token "$vault_namespace" "$vault_pod" "$vault_token"

  # Generate password
  local password
  password=$(generate_random_password "$vault_namespace" "$vault_pod" "$vault_token" "$length" "$format")

  # Save plaintext password to K8s secret for debug/testing (before hashing)
  save_plaintext_to_k8s_secret "$vault_path" "$password" "$vault_namespace"

  # Hash password if requested
  local final_password
  final_password=$(hash_password "$password" "$hashing")

  # Store in Vault
  store_password_in_vault "$vault_namespace" "$vault_pod" "$vault_token" "$vault_path" "$key_name" "$final_password"

  # Verify
  verify_storage "$vault_namespace" "$vault_pod" "$vault_token" "$vault_path" "$key_name"

  log ""
  log "===================================================="
  log "✅ Secret generation complete!"
  log "Path: ${vault_path}"
  log "===================================================="
}

main "$@"
