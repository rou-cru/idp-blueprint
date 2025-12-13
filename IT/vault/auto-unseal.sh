#!/bin/sh
set -e

echo "[Vault-Unsealer] Starting sidecar..."

# 1. Wait for Vault to be responsive (TCP connection)
# We loop until the local port 8200 replies, ensuring the main container is up.
until curl -s -o /dev/null http://127.0.0.1:8200/v1/sys/health; do
  echo "[Vault-Unsealer] Waiting for Vault API at localhost:8200..."
  sleep 5
done

echo "[Vault-Unsealer] Vault API is reachable."

# 2. Check for keys (Bootstrap vs Recovery)
# The secret 'vault-init-keys' is mounted at /vault/secrets/unseal-key
if [ ! -f /vault/secrets/unseal-key ]; then
  echo "[Vault-Unsealer] No unseal key found at /vault/secrets/unseal-key."
  echo "[Vault-Unsealer] Assuming this is the initial bootstrap phase."
  echo "[Vault-Unsealer] Sleeping indefinitely..."
  sleep infinity
fi

echo "[Vault-Unsealer] Unseal key found. Checking Vault status..."
STATUS=$(curl -s http://127.0.0.1:8200/v1/sys/health)

# Vault status 501/503 means not ready/sealed. Check "sealed":true in JSON response.
if echo "$STATUS" | grep -q '"sealed":true'; then
  echo "[Vault-Unsealer] Vault is sealed. Attempting to unseal..."
  
  UNSEAL_KEY=$(cat /vault/secrets/unseal-key)
  # Construct JSON payload
  PAYLOAD="{\"key\": \"$UNSEAL_KEY\"}"
  
  RESPONSE=$(curl -s -X POST -d "$PAYLOAD" http://127.0.0.1:8200/v1/sys/unseal)
  echo "[Vault-Unsealer] Unseal response: $RESPONSE"
else
  echo "[Vault-Unsealer] Vault is NOT sealed (already initialized/unsealed)."
fi

echo "[Vault-Unsealer] Job finished. Sleeping indefinitely..."
sleep infinity
