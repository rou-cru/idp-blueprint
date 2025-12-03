# CI/CD Pipeline con Argo Workflows

Pipeline CI/CD básico para construcción de imágenes Docker usando Argo Workflows, Kaniko y docker.io.

## Arquitectura del Pipeline

```
Trigger → Argo Workflow → DAG Execution
                              ↓
                    ┌─────────────────────┐
                    │  1. Git Clone       │
                    │  (alpine/git)       │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │  2. Hadolint        │
                    │  (Dockerfile lint)  │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │  3. Kaniko Build    │
                    │  (build & push)     │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │  4. Structure Test  │
                    │  (validation)       │
                    └─────────────────────┘
```

## WorkflowTemplates Disponibles

### 1. docker-pipeline-mvp
Pipeline completo con testing: `clone → lint → build → test → push`

**Uso:**
```bash
kubectl create -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: build-myapp-
  namespace: cicd
spec:
  workflowTemplateRef:
    name: docker-pipeline-mvp
  arguments:
    parameters:
    - name: repo-url
      value: "https://github.com/username/myapp.git"
    - name: branch
      value: "main"
    - name: dockerfile-path
      value: "Dockerfile"
    - name: context-path
      value: "."
    - name: image-name
      value: "username/myapp"
    - name: image-tag
      value: "v1.0.0"
    - name: docker-registry
      value: "docker.io"
EOF
```

### 2. docker-build-push
Pipeline simple sin testing: `clone → build → push`

**Uso:**
```bash
kubectl create -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: quick-build-
  namespace: cicd
spec:
  workflowTemplateRef:
    name: docker-build-push
  arguments:
    parameters:
    - name: repo-url
      value: "https://github.com/username/myapp.git"
    - name: branch
      value: "main"
    - name: image-name
      value: "username/myapp"
    - name: image-tag
      value: "latest"
EOF
```

## Configuración de Secrets

### Pre-requisitos: Vault Secrets

Los secrets de docker.io deben estar configurados en Vault antes de ejecutar workflows.

**1. Configurar credenciales en config.toml:**
```toml
[registry]
url = "docker.io"
username = "tu-username-dockerhub"
password = "tu-token-o-password"
```

**2. Seed secrets a Vault:**
```bash
task vault:generate-secrets
```

**3. Verificar ExternalSecret sync:**
```bash
# Verificar ExternalSecret está sincronizando
kubectl get externalsecret docker-registry-credentials -n cicd

# Verificar Secret fue creado
kubectl get secret docker-registry-credentials -n cicd

# Ver contenido del secret (base64 encoded)
kubectl get secret docker-registry-credentials -n cicd -o jsonpath='{.data}'
```

### Troubleshooting Secrets

Si el workflow falla con error de autenticación:

```bash
# 1. Verificar que Vault tiene los secrets
kubectl exec -n vault-system vault-0 -- \
  env VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=<root-token> \
  vault kv get secret/docker/registry

# 2. Forzar refresh del ExternalSecret
kubectl annotate externalsecret docker-registry-credentials -n cicd \
  force-sync="$(date +%s)" --overwrite

# 3. Verificar logs del workflow
kubectl logs -n cicd -l workflows.argoproj.io/workflow=<workflow-name> -c main
```

## Parámetros del Pipeline

### docker-pipeline-mvp

| Parámetro | Descripción | Default | Ejemplo |
|-----------|-------------|---------|---------|
| `repo-url` | URL del repositorio Git | - | `https://github.com/user/repo.git` |
| `branch` | Branch a clonar | `main` | `develop`, `feature/xyz` |
| `dockerfile-path` | Path al Dockerfile | `Dockerfile` | `build/Dockerfile`, `Dockerfile.prod` |
| `context-path` | Build context path | `.` | `src/`, `app/` |
| `image-name` | Nombre de imagen Docker | - | `username/myapp` |
| `image-tag` | Tag de la imagen | `latest` | `v1.2.3`, `sha-abc123` |
| `docker-registry` | Registry destino | `docker.io` | `ghcr.io`, `quay.io` |

## Monitoreo de Workflows

### Ver workflows en ejecución:
```bash
kubectl get workflows -n cicd
```

### Ver detalle de un workflow:
```bash
kubectl describe workflow <workflow-name> -n cicd
```

### Ver logs de un workflow:
```bash
# Logs de todos los steps
kubectl logs -n cicd -l workflows.argoproj.io/workflow=<workflow-name>

# Logs de step específico
kubectl logs -n cicd <workflow-name>-<node-id> -c main
```

### Seguir progreso en tiempo real:
```bash
kubectl get workflows -n cicd -w
```

### Acceder a UI de Argo Workflows:
```bash
# Obtener DNS suffix
DNS_SUFFIX=$(kubectl get gateway idp-gateway -n kube-system -o jsonpath='{.spec.listeners[0].hostname}' | sed 's/\*/workflows/')

# Abrir en browser
echo "https://${DNS_SUFFIX}"
```

## Testing del Pipeline

### Test 1: Pipeline completo con repositorio público

```bash
kubectl create -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: test-pipeline-
  namespace: cicd
spec:
  workflowTemplateRef:
    name: docker-pipeline-mvp
  arguments:
    parameters:
    - name: repo-url
      value: "https://github.com/GoogleContainerTools/distroless"
    - name: branch
      value: "main"
    - name: dockerfile-path
      value: "examples/nodejs/Dockerfile"
    - name: context-path
      value: "examples/nodejs"
    - name: image-name
      value: "tu-username/test-distroless"
    - name: image-tag
      value: "test-$(date +%Y%m%d-%H%M%S)"
EOF

# Seguir ejecución
kubectl get workflows -n cicd -w
```

### Test 2: Build rápido sin testing

```bash
kubectl create -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: quick-test-
  namespace: cicd
spec:
  workflowTemplateRef:
    name: docker-build-push
  arguments:
    parameters:
    - name: repo-url
      value: "https://github.com/docker-library/hello-world"
    - name: image-name
      value: "tu-username/hello-test"
    - name: image-tag
      value: "test"
EOF
```

## Customización del Pipeline

### Agregar security scanning (Trivy)

Editar `docker-pipeline-mvp.yaml` y agregar step en el DAG:

```yaml
- name: security-scan
  template: trivy-scan
  depends: build-and-push

# Agregar template
- name: trivy-scan
  container:
    image: aquasec/trivy:latest
    args:
      - image
      - --severity HIGH,CRITICAL
      - --exit-code 1
      - "{{workflow.parameters.docker-registry}}/{{workflow.parameters.image-name}}:{{workflow.parameters.image-tag}}"
```

### Modificar tests de Dockerfile

Editar `container-tests-config.yaml` ConfigMap para agregar tests específicos de tu aplicación.

### Agregar notificaciones

Usar Argo Events para triggear notificaciones en Slack/Teams cuando workflow completa:

```yaml
# Crear EventSource para workflow events
# Crear Sensor que envía mensaje a webhook
```

## Integración con Backstage (Fase 2)

El pipeline está diseñado para ser invocado desde Backstage Software Templates:

```yaml
# En Backstage template catalog-info.yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
spec:
  steps:
    - id: trigger-build
      name: Build Docker Image
      action: kubernetes:apply
      input:
        manifest:
          apiVersion: argoproj.io/v1alpha1
          kind: Workflow
          metadata:
            generateName: ${{ parameters.name }}-build-
            namespace: cicd
          spec:
            workflowTemplateRef:
              name: docker-pipeline-mvp
            arguments:
              parameters:
                - name: repo-url
                  value: ${{ parameters.repoUrl }}
                - name: image-name
                  value: ${{ parameters.dockerRegistry }}/${{ parameters.name }}
```

## Troubleshooting

### Error: "failed to get image source details: unsupported MediaType"

**Causa:** Registry credentials incorrectas o expired token

**Solución:**
1. Regenerar Docker Hub access token
2. Actualizar config.toml
3. Re-seed Vault: `task vault:generate-secrets`

### Error: "Error response from daemon: pull access denied"

**Causa:** Secret no montado correctamente o formato incorrecto

**Solución:**
```bash
# Verificar formato del secret
kubectl get secret docker-registry-credentials -n cicd -o yaml

# Debe tener type: kubernetes.io/dockerconfigjson
# Y key: .dockerconfigjson
```

### Workflow stuck en "Pending"

**Causa:** Recursos insuficientes o PriorityClass issue

**Solución:**
```bash
# Ver recursos del cluster
kubectl top nodes

# Ver pending pods
kubectl get pods -n cicd | grep Pending

# Describe para ver razón
kubectl describe pod <pod-name> -n cicd
```

### Hadolint falla con errores de linting

**Solución:** Revisar y corregir Dockerfile:
```bash
# Ver issues específicos en logs del workflow
kubectl logs -n cicd <workflow-name>-lint-dockerfile -c main

# Ejecutar hadolint localmente para debug
docker run --rm -i hadolint/hadolint < Dockerfile
```

## Best Practices

1. **Tagging:** Usar semantic versioning (`v1.2.3`) o commit SHA para tags
2. **Secrets:** Nunca hardcodear credentials, siempre usar Vault
3. **Cache:** Habilitar cache de Kaniko para builds más rápidos
4. **Resources:** Ajustar limits/requests según tamaño de build
5. **Cleanup:** Configurar TTL de workflows para no llenar etcd
6. **Monitoring:** Usar ServiceMonitor de Argo Workflows en Grafana

## Referencias

- [Argo Workflows Docs](https://argoproj.github.io/argo-workflows/)
- [Kaniko Documentation](https://github.com/GoogleContainerTools/kaniko)
- [Hadolint Rules](https://github.com/hadolint/hadolint#rules)
- [Container Structure Tests](https://github.com/GoogleContainerTools/container-structure-test)
