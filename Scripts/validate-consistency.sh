#!/usr/bin/env bash
set -euo pipefail

# Verificar que yq está disponible
if ! command -v yq &> /dev/null; then
  echo "Error: yq is not installed" >&2
  exit 1
fi

# Leer valores canónicos desde IT/kustomization.yaml (source of truth)
ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
CANONICAL_KUSTOMIZATION="$ROOT_DIR/IT/kustomization.yaml"

if [ ! -f "$CANONICAL_KUSTOMIZATION" ]; then
  echo "Error: $CANONICAL_KUSTOMIZATION not found" >&2
  exit 1
fi

CANONICAL_PART_OF=$(yq '.labels[0].pairs["app.kubernetes.io/part-of"]' "$CANONICAL_KUSTOMIZATION")
CANONICAL_OWNER=$(yq '.labels[0].pairs["owner"]' "$CANONICAL_KUSTOMIZATION")
CANONICAL_BUSINESS_UNIT=$(yq '.labels[0].pairs["business-unit"]' "$CANONICAL_KUSTOMIZATION")
CANONICAL_ENVIRONMENT=$(yq '.labels[0].pairs["environment"]' "$CANONICAL_KUSTOMIZATION")

ERRORS=0

# 1. Verificar labels en namespaces IT/
for ns in IT/namespaces/*.yaml; do
  if [[ "$ns" != *"kustomization.yaml" ]]; then
    ns_part_of=$(yq '.metadata.labels["app.kubernetes.io/part-of"] // ""' "$ns")
    ns_owner=$(yq '.metadata.labels["owner"] // ""' "$ns")
    ns_bu=$(yq '.metadata.labels["business-unit"] // ""' "$ns")
    ns_env=$(yq '.metadata.labels["environment"] // ""' "$ns")

    if [ "$ns_part_of" != "$CANONICAL_PART_OF" ]; then
      echo "Error: $ns missing label part-of (expected: $CANONICAL_PART_OF, got: $ns_part_of)"
      ERRORS=$((ERRORS + 1))
    fi
    if [ "$ns_owner" != "$CANONICAL_OWNER" ]; then
      echo "Error: $ns missing label owner (expected: $CANONICAL_OWNER, got: $ns_owner)"
      ERRORS=$((ERRORS + 1))
    fi
    if [ "$ns_bu" != "$CANONICAL_BUSINESS_UNIT" ]; then
      echo "Error: $ns missing label business-unit (expected: $CANONICAL_BUSINESS_UNIT, got: $ns_bu)"
      ERRORS=$((ERRORS + 1))
    fi
    if [ "$ns_env" != "$CANONICAL_ENVIRONMENT" ]; then
      echo "Error: $ns missing label environment (expected: $CANONICAL_ENVIRONMENT, got: $ns_env)"
      ERRORS=$((ERRORS + 1))
    fi
  fi
done

# 2. Verificar owner y business-unit consistency
KUSTOMIZATIONS=(
  "IT/kustomization.yaml"
  "IT/argocd/kustomization.yaml"
  "K8s/argocd/kustomization.yaml"
  "K8s/cicd/infrastructure/kustomization.yaml"
)

declare -A OWNER_VALUES
for kust in "${KUSTOMIZATIONS[@]}"; do
  if [ -f "$kust" ]; then
    owner=$(yq '.labels[0].pairs["owner"] // ""' "$kust")
    if [ -n "$owner" ]; then
      OWNER_VALUES["$owner"]=1
    fi
  fi
done

if [ "${#OWNER_VALUES[@]}" -ne 1 ]; then
  echo "Error: Inconsistent 'owner' values across kustomizations"
  for val in "${!OWNER_VALUES[@]}"; do
    echo "  - $val"
  done
  ERRORS=$((ERRORS + 1))
fi

declare -A BU_VALUES
for kust in "${KUSTOMIZATIONS[@]}"; do
  if [ -f "$kust" ]; then
    bu=$(yq '.labels[0].pairs["business-unit"] // ""' "$kust")
    if [ -n "$bu" ]; then
      BU_VALUES["$bu"]=1
    fi
  fi
done

if [ "${#BU_VALUES[@]}" -ne 1 ]; then
  echo "Error: Inconsistent 'business-unit' values across kustomizations"
  for val in "${!BU_VALUES[@]}"; do
    echo "  - $val"
  done
  ERRORS=$((ERRORS + 1))
fi

# 3. Verificar kustomizations con labels pero sin resources
while IFS= read -r kust; do
  # Skip label-only overlays (K8s/argocd, K8s/vault)
  if [[ "$kust" == *"K8s/argocd/kustomization.yaml" ]] || [[ "$kust" == *"K8s/vault/kustomization.yaml" ]]; then
    continue
  fi

  has_labels=$(yq '.labels // null' "$kust")
  has_resources=$(yq '.resources // null' "$kust")

  if [ "$has_labels" != "null" ] && [ "$has_resources" == "null" ]; then
    echo "Error: $kust has labels but no resources"
    ERRORS=$((ERRORS + 1))
  fi
done < <(find . -name "kustomization.yaml" 2>/dev/null)

# 4. Verificar priorityClassName coverage
TOTAL_VALUES_FILES=$(find . -name "*-values.yaml" 2>/dev/null | wc -l)
ACTUAL=0

while IFS= read -r f; do
  has_priority=$(yq '.. | select(has("priorityClassName")) | .priorityClassName' "$f" 2>/dev/null || true)
  if [ -n "$has_priority" ]; then
    ACTUAL=$((ACTUAL + 1))
  fi
done < <(find . -name "*-values.yaml" 2>/dev/null)

if [ "$ACTUAL" -ne "$TOTAL_VALUES_FILES" ]; then
  echo "Warning: priorityClassName coverage: $ACTUAL/$TOTAL_VALUES_FILES files"
  while IFS= read -r f; do
    has_priority=$(yq '.. | select(has("priorityClassName")) | .priorityClassName' "$f" 2>/dev/null || true)
    if [ -z "$has_priority" ]; then
      echo "  - $f"
    fi
  done < <(find . -name "*-values.yaml" 2>/dev/null)
fi

# Exit
if [ "$ERRORS" -gt 0 ]; then
  echo "Validation failed: $ERRORS error(s)"
  exit 1
fi
