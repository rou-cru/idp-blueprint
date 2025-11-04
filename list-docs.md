# Archivos pendientes de corrección para helm-docs

## Tarea
Eliminar redundancia en documentación de helm-docs causada por comentarios `# --` en objetos intermedios que tienen valores hijos.

## Problema
Cuando un objeto con hijos tiene un comentario `# --`, helm-docs genera documentación redundante:
- Documenta el objeto completo con JSON embebido (inútil)
- Documenta cada valor hijo individualmente (correcto)

**Ejemplo de redundancia**:
```
| resources | object | `{"limits":{"cpu":"500m","memory":"1Gi"},...}` | Resource limits |
| resources.limits.cpu | string | `"500m"` | CPU limit |
| resources.limits.memory | string | `"1Gi"` | Memory limit |
```

## Solución
1. **Eliminar** comentarios `# -- (object)` de objetos que tienen hijos
2. **Mantener** comentarios solo en valores finales (leaf nodes)
3. **Agregar** comentarios individuales a valores que no los tengan

**Ejemplo correcto**:
```yaml
resources:
  requests:
    # -- (string) CPU request
    cpu: 100m
    # -- (string) Memory request
    memory: 128Mi
  limits:
    # -- (string) CPU limit
    cpu: 500m
    # -- (string) Memory limit
    memory: 1Gi
```

## Archivos pendientes (6)

### IT/cert-manager/cert-manager-values.yaml
- **Bloques con redundancia**: 3
- **Ubicación típica**: `resources`, `webhook.resources`, `cainjector.resources`

### K8s/cicd/argo-workflows/argo-workflows-values.yaml
- **Bloques con redundancia**: 3
- **Ubicación típica**: `controller.resources`, `server.resources`, etc.

### K8s/cicd/jenkins.disabled/jenkins-values.yaml
- **Bloques con redundancia**: 1
- **Ubicación típica**: `controller.resources`

### K8s/cicd/sonarqube/sonarqube-values.yaml
- **Bloques con redundancia**: 2
- **Ubicación típica**: `sonarqube.resources`, otros componentes

### Policies/kyverno/kyverno-values.yaml
- **Bloques con redundancia**: 1
- **Ubicación típica**: `resources` o componentes internos

### Policies/policy-reporter/policy-reporter-values.yaml
- **Bloques con redundancia**: 2
- **Ubicación típica**: `policyReporter.resources`, `ui.resources`

## Archivos ya corregidos ✅
- IT/vault/vault-values.yaml
- IT/argocd/argocd-values.yaml
- IT/cilium/cilium-values.yaml
- IT/external-secrets/eso-values.yaml
- K8s/security/trivy/trivy-values.yaml
- K8s/observability/fluent-bit/fluent-bit-values.yaml
- K8s/observability/loki/loki-values.yaml
- K8s/observability/kube-prometheus-stack/kube-prometheus-stack-values.yaml

## Comando para verificar después de la corrección
```bash
./scripts/helm-docs-generate.sh
grep "resources.*object.*{\"limits" */*/README.md */*/*/README.md
```

Si no hay output, todos los archivos están correctos.
