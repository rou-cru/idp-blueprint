#!/bin/bash
set -e

echo "🔍 Validando consistencia del repositorio..."
echo ""

# Verificar que yq está disponible
if ! command -v yq &> /dev/null; then
  echo "❌ Error: yq no está instalado. Instálalo desde: https://github.com/mikefarah/yq"
  exit 1
fi

# Leer valores canónicos desde IT/kustomization.yaml (source of truth)
ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
CANONICAL_KUSTOMIZATION="$ROOT_DIR/IT/kustomization.yaml"

if [ ! -f "$CANONICAL_KUSTOMIZATION" ]; then
  echo "❌ Error: No se encuentra $CANONICAL_KUSTOMIZATION"
  exit 1
fi

CANONICAL_PART_OF=$(yq -r '.labels[0].pairs["app.kubernetes.io/part-of"]' "$CANONICAL_KUSTOMIZATION")
CANONICAL_OWNER=$(yq -r '.labels[0].pairs["owner"]' "$CANONICAL_KUSTOMIZATION")
CANONICAL_BUSINESS_UNIT=$(yq -r '.labels[0].pairs["business-unit"]' "$CANONICAL_KUSTOMIZATION")
CANONICAL_ENVIRONMENT=$(yq -r '.labels[0].pairs["environment"]' "$CANONICAL_KUSTOMIZATION")

echo "📋 Valores canónicos desde $CANONICAL_KUSTOMIZATION:"
echo "   part-of: $CANONICAL_PART_OF"
echo "   owner: $CANONICAL_OWNER"
echo "   business-unit: $CANONICAL_BUSINESS_UNIT"
echo "   environment: $CANONICAL_ENVIRONMENT"
echo ""

ERRORS=0

# 1. Verificar que no hay valores "None"
echo "1. Verificando valores 'None'..."
if grep -r "None" IT/kustomization.yaml K8s/ 2>/dev/null; then
  echo "  ❌ Encontrados valores 'None'"
  ((ERRORS++))
else
  echo "  ✅ No hay valores 'None'"
fi

# 2. Verificar labels en namespaces IT/
echo ""
echo "2. Verificando labels en namespaces IT/..."
NS_ERRORS=0
for ns in IT/namespaces/*.yaml; do
  if [[ "$ns" != *"kustomization.yaml" ]]; then
    if ! grep -q "app.kubernetes.io/part-of: $CANONICAL_PART_OF" "$ns"; then
      echo "  ❌ $ns falta label part-of (esperado: $CANONICAL_PART_OF)"
      ((NS_ERRORS++))
    fi
    if ! grep -q "owner: $CANONICAL_OWNER" "$ns"; then
      echo "  ❌ $ns falta label owner (esperado: $CANONICAL_OWNER)"
      ((NS_ERRORS++))
    fi
    if ! grep -q "business-unit: $CANONICAL_BUSINESS_UNIT" "$ns"; then
      echo "  ❌ $ns falta label business-unit (esperado: $CANONICAL_BUSINESS_UNIT)"
      ((NS_ERRORS++))
    fi
    if ! grep -q "environment: $CANONICAL_ENVIRONMENT" "$ns"; then
      echo "  ❌ $ns falta label environment (esperado: $CANONICAL_ENVIRONMENT)"
      ((NS_ERRORS++))
    fi
  fi
done
if [ $NS_ERRORS -eq 0 ]; then
  echo "  ✅ Todos los namespaces IT tienen los labels requeridos"
else
  echo "  ❌ Errores en labels de namespaces: $NS_ERRORS"
  ((ERRORS+=$NS_ERRORS))
fi

# 3. Verificar owner y business-unit consistency
echo ""
echo "3. Verificando consistencia de 'owner' y 'business-unit'..."

# Lista de kustomizations a verificar (DRY - single source)
KUSTOMIZATIONS="IT/kustomization.yaml IT/argocd/kustomization.yaml K8s/argocd/kustomization.yaml K8s/cicd/infrastructure/kustomization.yaml"

OWNER_VALUES=$(grep -h "owner:" $KUSTOMIZATIONS 2>/dev/null | awk '{print $2}' | sort -u | wc -l)
if [ "$OWNER_VALUES" -eq 1 ]; then
  echo "  ✅ Valor de 'owner' consistente en todos los kustomizations"
else
  echo "  ❌ Valores de 'owner' inconsistentes:"
  grep -h "owner:" $KUSTOMIZATIONS 2>/dev/null | sort -u
  ((ERRORS++))
fi

BU_VALUES=$(grep -h "business-unit:" $KUSTOMIZATIONS 2>/dev/null | awk '{print $2}' | sort -u | wc -l)
if [ "$BU_VALUES" -eq 1 ]; then
  echo "  ✅ Valor de 'business-unit' consistente en todos los kustomizations"
else
  echo "  ❌ Valores de 'business-unit' inconsistentes:"
  grep -h "business-unit:" $KUSTOMIZATIONS 2>/dev/null | sort -u
  ((ERRORS++))
fi

# 4. Verificar comment style
echo ""
echo "4. Verificando comment style en values files..."
if grep -r "^## @section" IT/ K8s/ Policies/ --include="*-values.yaml" 2>/dev/null; then
  echo "  ❌ Encontrado comment style ## @section (debe ser # @section --)"
  ((ERRORS++))
else
  echo "  ✅ Comment style consistente (# @section --)"
fi

# 5. Verificar kustomizations con labels pero sin resources (excepto K8s/argocd y K8s/vault)
echo ""
echo "5. Verificando kustomizations con labels pero sin resources..."
KUST_ERRORS=0
for kust in $(find . -name "kustomization.yaml" 2>/dev/null); do
  # Skip label-only overlays (K8s/argocd, K8s/vault)
  if [[ "$kust" == *"K8s/argocd/kustomization.yaml" ]] || [[ "$kust" == *"K8s/vault/kustomization.yaml" ]]; then
    continue
  fi
  if grep -q "^labels:" "$kust" && ! grep -q "^resources:" "$kust"; then
    echo "  ❌ $kust tiene labels pero no resources"
    ((KUST_ERRORS++))
  fi
done
if [ $KUST_ERRORS -eq 0 ]; then
  echo "  ✅ Todos los kustomizations con labels tienen resources (excepto overlays conocidos)"
else
  echo "  ❌ Kustomizations inválidos: $KUST_ERRORS"
  ((ERRORS+=$KUST_ERRORS))
fi

# 6. Verificar priorityClassName coverage
echo ""
echo "6. Verificando cobertura de priorityClassName..."

# Contar dinámicamente todos los *-values.yaml excluyendo jenkins.disabled
TOTAL_VALUES_FILES=$(find . -name "*-values.yaml" -not -path "*/jenkins.disabled/*" 2>/dev/null | wc -l)
ACTUAL=$(find . -name "*-values.yaml" -not -path "*/jenkins.disabled/*" -exec grep -l "priorityClassName" {} \; 2>/dev/null | wc -l)

if [ $ACTUAL -eq $TOTAL_VALUES_FILES ]; then
  echo "  ✅ Priority class coverage: 100% ($ACTUAL/$TOTAL_VALUES_FILES archivos)"
else
  echo "  ⚠️  Priority class coverage: $ACTUAL/$TOTAL_VALUES_FILES archivos"
  echo "  📋 Archivos sin priorityClassName:"
  find . -name "*-values.yaml" -not -path "*/jenkins.disabled/*" 2>/dev/null | while read -r f; do
    if ! grep -q "priorityClassName" "$f"; then
      echo "      - $f"
    fi
  done
fi

# 7. Verificar API version deprecated
echo ""
echo "7. Verificando API versions deprecated..."
if grep -r "external-secrets.io/v1beta1" K8s/ 2>/dev/null; then
  echo "  ❌ Encontrada API version deprecated v1beta1"
  ((ERRORS++))
else
  echo "  ✅ No hay API versions deprecated"
fi

# Resumen final
echo ""
echo "═══════════════════════════════════════════"
if [ $ERRORS -eq 0 ]; then
  echo "✅ Todas las validaciones pasaron"
  echo "═══════════════════════════════════════════"
  exit 0
else
  echo "❌ Validaciones fallidas: $ERRORS"
  echo "═══════════════════════════════════════════"
  exit 1
fi
