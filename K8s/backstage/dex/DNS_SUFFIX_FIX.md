# DNS_SUFFIX Fix para Dex

El error `can't parse issuer URL` ocurre porque `${DNS_SUFFIX}` no está siendo reemplazado en el ConfigMap de Dex.

## Solución: Usar envsubst (Como el resto del proyecto)

El proyecto ya usa `envsubst` para reemplazar variables en otros ApplicationSets. Aplicar el mismo patrón:

### Opción 1: Via ArgoCD ApplicationSet (Recomendado)

El ApplicationSet de Backstage ya debe aplicar con `envsubst`:

```bash
# En Task/stacks.yaml o manualmente:
export DNS_SUFFIX=$(kubectl get cm -n kube-system cluster-info -o jsonpath='{.data.DNS_SUFFIX}' 2>/dev/null || \
  echo "$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' | tr '.' '-').nip.io")

# Aplicar ApplicationSet con envsubst (esto desplegará todo Backstage incluyendo Dex)
envsubst < K8s/backstage/applicationset-backstage.yaml | kubectl apply -f -
```

### Opción 2: Aplicar Dex Directamente con Kustomize + envsubst

```bash
# Exportar DNS_SUFFIX
export DNS_SUFFIX=$(kubectl get cm -n kube-system cluster-info -o jsonpath='{.data.DNS_SUFFIX}' 2>/dev/null || \
  echo "$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' | tr '.' '-').nip.io")

# Aplicar con envsubst (patrón del proyecto)
kustomize build K8s/backstage/dex | envsubst | kubectl apply -f -

# Reiniciar Dex
kubectl rollout restart deployment/dex -n backstage
```

### Opción 3: Fix Rápido (Si ya está desplegado)

```bash
# Obtener DNS actual
DNS_SUFFIX=$(kubectl get cm -n kube-system cluster-info -o jsonpath='{.data.DNS_SUFFIX}')

# Actualizar ConfigMap en caliente
kubectl get cm -n backstage dex-config -o yaml | \
  sed "s/\${DNS_SUFFIX}/$DNS_SUFFIX/g" | \
  kubectl apply -f -

# Reiniciar
kubectl rollout restart deployment/dex -n backstage
```

## Verificar

```bash
# Ver logs de Dex
kubectl logs -n backstage deployment/dex | head -20

# Debe mostrar:
# config issuer: https://dex.192-168-1-100.nip.io  (o tu dominio)
# ✅ Sin error "can't parse issuer URL"
```

## Integración con Task

Si usas Taskfile, asegúrate que el stack de Backstage use envsubst:

```yaml
# En Task/stacks.yaml
backstage:deploy:
  preconditions:
    - sh: command -v envsubst
      msg: 'envsubst required'
  env:
    DNS_SUFFIX:
      sh: |
        # Calcular DNS_SUFFIX igual que en gateway:deploy
  cmds:
    - envsubst < K8s/backstage/applicationset-backstage.yaml | kubectl apply -f -
```

