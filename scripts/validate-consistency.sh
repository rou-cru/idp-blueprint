#!/bin/bash
set -e

echo "🔍 Validando consistencia del repositorio..."
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
    if ! grep -q "app.kubernetes.io/part-of: idp" "$ns"; then
      echo "  ❌ $ns falta label part-of"
      ((NS_ERRORS++))
    fi
    if ! grep -q "owner: platform-team" "$ns"; then
      echo "  ❌ $ns falta label owner"
      ((NS_ERRORS++))
    fi
    if ! grep -q "business-unit: infrastructure" "$ns"; then
      echo "  ❌ $ns falta label business-unit"
      ((NS_ERRORS++))
    fi
    if ! grep -q "environment: demo" "$ns"; then
      echo "  ❌ $ns falta label environment"
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

# 3. Verificar owner consistency
echo ""
echo "3. Verificando consistencia de 'owner'..."
OWNER_VALUES=$(grep -h "owner:" IT/kustomization.yaml IT/argocd/kustomization.yaml K8s/argocd/kustomization.yaml K8s/cicd/infrastructure/kustomization.yaml 2>/dev/null | awk '{print $2}' | sort -u | wc -l)
if [ "$OWNER_VALUES" -eq 1 ]; then
  echo "  ✅ Valor de 'owner' consistente en todos los kustomizations"
else
  echo "  ❌ Valores de 'owner' inconsistentes"
  grep -h "owner:" IT/kustomization.yaml IT/argocd/kustomization.yaml K8s/argocd/kustomization.yaml K8s/cicd/infrastructure/kustomization.yaml 2>/dev/null | sort -u
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
EXPECTED_PRIORITY_FILES=11  # Excluyendo jenkins.disabled
ACTUAL=$(find . -name "*-values.yaml" -not -path "*/jenkins.disabled/*" -exec grep -l "priorityClassName" {} \; 2>/dev/null | wc -l)
if [ $ACTUAL -ge $EXPECTED_PRIORITY_FILES ]; then
  echo "  ✅ Priority class coverage: $ACTUAL/$EXPECTED_PRIORITY_FILES o más"
else
  echo "  ⚠️  Priority class coverage: $ACTUAL/$EXPECTED_PRIORITY_FILES"
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
