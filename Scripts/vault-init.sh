#!/usr/bin/env bash
set -euo pipefail

# Manual Vault initialization script
# This script must be run ONCE after Vault is deployed

readonly NAMESPACE="vault-system"
readonly SECRET_NAME="vault-init-keys"

log() {
  echo "$*" >&2
}

wait_for_vault_pod() {
  local max_attempts=60
  local attempt=0

  log "Waiting for Vault pod to be available..."

  while [ $attempt -lt $max_attempts ]; do
    # Check 1: Pod exists and is running
    if ! kubectl get pod vault-0 -n "$NAMESPACE" &>/dev/null; then
      log "Pod vault-0 not found yet (attempt ${attempt}/${max_attempts})"
      attempt=$((attempt + 1))
      sleep 5
      continue
    fi

    # Check 2: Pod has been assigned to a node
    pod_phase=$(kubectl get pod vault-0 -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null)
    if [ "$pod_phase" != "Running" ] && [ "$pod_phase" != "Succeeded" ]; then
      log "Pod is in phase '$pod_phase', waiting... (attempt ${attempt}/${max_attempts})"
      attempt=$((attempt + 1))
      sleep 5
      continue
    fi

    # Check 3: Vault API is responsive (even if sealed/uninitialized)
    # Note: vault status returns exit code 2 when sealed/uninitialized, but still outputs valid JSON
    # Temporarily disable pipefail for this check since vault status returns non-zero exit codes
    set +o pipefail
    if kubectl exec -n "$NAMESPACE" vault-0 -- vault status -format=json 2>/dev/null | jq -e '.version' >/dev/null 2>&1; then
      set -o pipefail
      return 0
    fi
    set -o pipefail

    log "Vault API not ready yet (attempt ${attempt}/${max_attempts})"
    attempt=$((attempt + 1))
    sleep 5
  done

  log "ERROR: Vault pod not ready after $((max_attempts * 5)) seconds"
  log "Current pod status:"
  kubectl get pod vault-0 -n "$NAMESPACE" -o wide 2>&1 || true
  kubectl describe pod vault-0 -n "$NAMESPACE" 2>&1 | tail -20 || true
  return 1
}

main() {
  # Wait for Vault pod to be ready before attempting operations
  if ! wait_for_vault_pod; then
    log "ERROR: Cannot proceed without Vault pod being available"
    exit 1
  fi

  # 1. Check if Vault is already initialized
  if kubectl exec -n "$NAMESPACE" vault-0 -- vault status -format=json 2>/dev/null | jq -e '.initialized == true' >/dev/null 2>&1; then
    log "Vault is already initialized. Checking seal status..."

    if kubectl exec -n "$NAMESPACE" vault-0 -- vault status -format=json 2>/dev/null | jq -e '.sealed == true' >/dev/null; then
      log "Vault is sealed. Retrieving unseal key..."
      UNSEAL_KEY=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.unseal-key}' 2>/dev/null | base64 -d)

      if [ -z "$UNSEAL_KEY" ]; then
        log "ERROR: Cannot retrieve unseal key from secret '$SECRET_NAME'"
        exit 1
      fi

      log "Unsealing Vault..."
      kubectl exec -n "$NAMESPACE" vault-0 -- vault operator unseal "$UNSEAL_KEY"
      log "✅ Vault unsealed successfully"
    else
      log "✅ Vault is already initialized and unsealed"
    fi
    exit 0
  fi

  # 2. Initialize Vault
  INIT_OUTPUT=$(kubectl exec -n "$NAMESPACE" vault-0 -- vault operator init \
    -key-shares=1 \
    -key-threshold=1 \
    -format=json)

  UNSEAL_KEY=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[0]')
  ROOT_TOKEN=$(echo "$INIT_OUTPUT" | jq -r '.root_token')

  if [ -z "$UNSEAL_KEY" ] || [ -z "$ROOT_TOKEN" ]; then
    log "ERROR: Failed to extract unseal key or root token"
    exit 1
  fi

  log "✅ Vault initialized successfully"

  # 3. Unseal Vault
  log "Unsealing Vault..."
  kubectl exec -n "$NAMESPACE" vault-0 -- vault operator unseal "$UNSEAL_KEY"
  log "✅ Vault unsealed"

  # 4. Persist keys to Kubernetes Secret
  kubectl create secret generic "$SECRET_NAME" -n "$NAMESPACE" \
    --from-literal=unseal-key="$UNSEAL_KEY" \
    --from-literal=root-token="$ROOT_TOKEN" \
    --dry-run=client -o yaml | kubectl apply -f -
  log "✅ Keys saved to secret"

  # 5. Configure Vault for ESO (External Secrets Operator)
  log "Configuring Vault for ESO..."
  export ROOT_TOKEN

  # Enable Kubernetes auth
  kubectl exec -n "$NAMESPACE" vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" \
    vault auth enable kubernetes 2>/dev/null || log "Kubernetes auth already enabled"

  # Configure Kubernetes auth
  kubectl exec -n "$NAMESPACE" vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" \
    vault write auth/kubernetes/config \
    kubernetes_host="https://kubernetes.default.svc:443"

  # KV v2 for static secrets (passwords, tokens, API keys)
  kubectl exec -n "$NAMESPACE" vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" \
    vault secrets enable -path=secret kv-v2 2>/dev/null || log "KV v2 engine already enabled"

  # Database engine for dynamic DB credentials (PostgreSQL, MySQL, etc.)
  kubectl exec -n "$NAMESPACE" vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" \
    vault secrets enable database 2>/dev/null || log "Database engine already enabled"

  # Transit engine for encryption-as-a-service
  kubectl exec -n "$NAMESPACE" vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" \
    vault secrets enable transit 2>/dev/null || log "Transit engine already enabled"

  log "✅ Secrets engines enabled (kv-v2, database, transit)"

  # Create policy for ESO
  ESO_POLICY='path "secret/data/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "secret/metadata/*" {
  capabilities = ["list", "read"]
}'

  echo "$ESO_POLICY" | kubectl exec -n "$NAMESPACE" -i vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" \
    vault policy write eso-policy -

  # Create a namespace-specific role for ArgoCD with ESO
  kubectl exec -n "$NAMESPACE" vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" \
    vault write auth/kubernetes/role/eso-argocd-role \
    bound_service_account_names=external-secrets \
    bound_service_account_namespaces=argocd \
    policies=eso-policy \
    ttl=24h \
    audience=vault

  log "✅ Vault configured for ESO (ArgoCD namespace)"

  # Create a namespace-specific role for CICD with ESO
  kubectl exec -n "$NAMESPACE" vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" \
    vault write auth/kubernetes/role/eso-cicd-role \
    bound_service_account_names=external-secrets \
    bound_service_account_namespaces=cicd \
    policies=eso-policy \
    ttl=24h \
    audience=vault

  log "✅ Vault configured for ESO (CICD namespace)"

  # Create a namespace-specific role for Observability with ESO
  kubectl exec -n "$NAMESPACE" vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" \
    vault write auth/kubernetes/role/eso-observability-role \
    bound_service_account_names=external-secrets \
    bound_service_account_namespaces=observability \
    policies=eso-policy \
    ttl=24h \
    audience=vault

  log "=================================================="
  log "✅ Vault initialization complete!"
  log "Root token and unseal key saved in secret: $SECRET_NAME"
  log "=================================================="
}

main
