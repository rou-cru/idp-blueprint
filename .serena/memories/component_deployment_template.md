# Component Deployment Template and config.toml Guide

## Understanding config.toml

`config.toml` es el archivo de configuración centralizado del proyecto que controla:

### 1. Versiones de Componentes (`[versions]`)
Versiones de infraestructura y aplicaciones (Cilium, cert-manager, ArgoCD, Vault, etc.).
- Usado por: `Scripts/config-get.sh`, `Taskfile.yaml`, scripts de generación de metadata
- Relevancia debugging: Verificar compatibilidad de versiones entre componentes
- Test manual: Cambiar versión para probar upgrade/downgrade de componente específico

### 2. Network Configuration (`[network]`)
- `lan_ip`: IP LAN auto-detectada o manual para URLs `<service>.<ip>.nip.io`
- `nodeport_http`/`nodeport_https`: Puertos NodePort (default 30080/30443)
- Relevancia debugging: Verificar acceso a servicios expuestos
- Test manual: Cambiar puertos si hay conflictos con otros servicios locales

### 3. Git Repository (`[git]`)
- `repo_url`: Override del repo URL (default: remote.origin.url)
- `target_revision`: Override de branch/tag (default: current branch)
- Relevancia debugging: Probar ArgoCD con fork/branch diferente
- Test manual: Apuntar a feature branch para testing de cambios GitOps

### 4. Passwords (`[passwords]`)
- Credenciales para ArgoCD, Grafana, SonarQube, Vault, Backstage Dex
- Relevancia debugging: Credenciales conocidas para login manual
- Test manual: Cambiar passwords para probar rotación de secretos

### 5. Fuses (Feature Toggles) (`[fuses]`)
- `policies`, `security`, `observability`, `cicd`, `backstage`: true/false para habilitar stacks
- `prod`: false (default) para demo, true para perfil hardened con HA
- **Relevancia debugging CRÍTICA**: Deshabilitar stacks problemáticos para aislar issues
- **Test manual**: Desplegar solo subset de stacks para desarrollo/testing
- Implementación: Taskfile.yaml vars FUSE_* (default true excepto prod=false)
  - `stacks:deploy` task evalúa cada fuse antes de ejecutar `task stacks:<nombre>`

### 6. Registry Configuration (`[registry]`)
- URL, username, password para Docker registry privado
- Relevancia debugging: Verificar pull de imágenes privadas
- Test manual: Probar con registry local/privado

### 7. Operational Settings (`[operational]`)
- `kubectl_timeout`: timeout para operaciones kubectl (default 300s)
- `k3d_config`: path al config k3d (IT/k3d-cluster.yaml)
- `registry_cache_path`: path a cache de registry local
- Relevancia debugging: Ajustar timeouts para operaciones lentas
- Test manual: Reducir timeouts para fast-fail en CI

### 8. ArgoCD Configuration (`[argocd]`)
- Configuración de sync_timeout, backoff_duration, retry_limit
- Relevancia debugging: Ajustar para aplicaciones con sync lento
- Test manual: Reducir retry para identificar problemas más rápido

## Accessing config.toml Values

**Helper script**: `Scripts/config-get.sh <key> [config_file]`
- Usa `dasel` para parsear TOML
- Strip quotes automático de valores
- Ejemplo: `./Scripts/config-get.sh versions.cilium`
- Usado por: Taskfile.yaml (vars), scripts de generación de docs/metadata

**Taskfile vars**: Todas las keys de config.toml se exponen como vars en Taskfile.yaml
- Ejemplo: `{{.CILIUM_VERSION}}`, `{{.FUSE_POLICIES}}`, `{{.LAN_IP}}`
- Auto-detection fallbacks: LAN_IP, REPO_URL, TARGET_REVISION si vacíos en config

## Template Genérico para Nuevo Componente GitOps

### Estructura de Directorios Requerida

```
K8s/<nombre-stack>/
├── applicationset-<nombre-stack>.yaml    # ArgoCD ApplicationSet (OBLIGATORIO)
├── governance/                            # Namespace + quotas (OBLIGATORIO)
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── limitrange.yaml
│   └── resourcequota.yaml
├── infrastructure/                        # ESO + SecretStore (OPCIONAL si usa Vault)
│   ├── kustomization.yaml
│   ├── eso-<nombre-stack>.yaml
│   └── <nombre-stack>-secretstore.yaml
└── <componente>/                          # Aplicación (Helm o manifests)
    ├── kustomization.yaml
    ├── Chart.yaml                         # Si usa Helm
    ├── values.yaml                        # Si usa Helm
    └── README.md                          # Documentación
```

### 1. ApplicationSet Principal (OBLIGATORIO)

**Path**: `K8s/<nombre-stack>/applicationset-<nombre-stack>.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: <nombre-stack>
  namespace: argocd
  labels:
    app.kubernetes.io/part-of: idp
    app.kubernetes.io/component: applicationset
    owner: platform-team
    business-unit: infrastructure
    environment: demo
spec:
  generators:
    - git:
        repoURL: ${REPO_URL}
        revision: ${TARGET_REVISION}
        directories:
          - path: K8s/<nombre-stack>/*
  template:
    metadata:
      name: "<nombre-stack>-{{path.basename}}"
    spec:
      project: <nombre-stack>
      source:
        repoURL: ${REPO_URL}
        targetRevision: ${TARGET_REVISION}
        path: "{{path}}"
        kustomize: {}
      destination:
        server: https://kubernetes.default.svc
        namespace: <nombre-namespace>
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - ServerSideApply=true
          - PruneLast=true
          - ApplyOutOfSyncOnly=true
          - RespectIgnoreDifferences=true
        retry:
          limit: 10
          backoff:
            duration: 10s
            factor: 2
            maxDuration: 10m
      ignoreDifferences:
        - group: ""
          kind: Secret
          jsonPointers:
            - /data
            - /metadata/labels
        - group: ""
          kind: ServiceAccount
          jsonPointers:
            - /secrets
        - group: external-secrets.io
          kind: ExternalSecret
          jsonPointers:
            - /status
            - /metadata/generation
        - group: apps
          kind: StatefulSet
          jsonPointers:
            - /status
```

**Notas**:
- `${REPO_URL}` y `${TARGET_REVISION}` son substituidos por `envsubst` (Task/stacks.yaml)
- `project` debe existir en ArgoCD o usar `default`
- Patrón `K8s/<nombre-stack>/*` descubre todos los subdirectorios automáticamente

### 2. Governance (OBLIGATORIO)

**Path**: `K8s/<nombre-stack>/governance/`

#### namespace.yaml
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: <nombre-namespace>
  annotations:
    argocd.argoproj.io/sync-wave: "-2"
  labels:
    app.kubernetes.io/part-of: idp
    business-unit: infrastructure
    owner: platform-team
    environment: demo
```

**Sync wave `-2`**: Asegura creación de namespace antes que otros recursos.

#### limitrange.yaml
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: <nombre-stack>-limits
  namespace: <nombre-namespace>
  labels:
    app.kubernetes.io/part-of: idp
spec:
  limits:
    - type: Container
      default:
        cpu: 500m
        memory: 512Mi
      defaultRequest:
        cpu: 100m
        memory: 128Mi
```

**Nota**: Ajustar defaults según workload esperado.

#### resourcequota.yaml
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: <nombre-stack>-quota
  namespace: <nombre-namespace>
  labels:
    app.kubernetes.io/part-of: idp
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
```

**Nota**: Ajustar según capacidad de hardware demo (default 4vCPU/8GiB RAM).

#### kustomization.yaml
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace.yaml
  - limitrange.yaml
  - resourcequota.yaml
```

### 3. Infrastructure (OPCIONAL - si usa External Secrets)

**Path**: `K8s/<nombre-stack>/infrastructure/`

#### eso-<nombre-stack>.yaml
```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: <nombre-stack>-eso
  namespace: <nombre-namespace>
  labels:
    app.kubernetes.io/part-of: idp
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: <nombre-stack>-secretstore
    kind: SecretStore
  target:
    name: <nombre-stack>-secret
    creationPolicy: Owner
  data:
    - secretKey: key-name
      remoteRef:
        key: secret/<nombre-stack>/path
        property: property-name
```

#### <nombre-stack>-secretstore.yaml
```yaml
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: <nombre-stack>-secretstore
  namespace: <nombre-namespace>
  labels:
    app.kubernetes.io/part-of: idp
spec:
  provider:
    vault:
      server: "http://vault.vault.svc.cluster.local:8200"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "external-secrets"
          serviceAccountRef:
            name: external-secrets-sa
```

**Nota**: `external-secrets-sa` debe existir en namespace (creado por ESO operator).

#### kustomization.yaml
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - eso-<nombre-stack>.yaml
  - <nombre-stack>-secretstore.yaml

labels:
  - includeSelectors: true
    pairs:
      app.kubernetes.io/part-of: idp
      owner: platform-team
      business-unit: infrastructure
      environment: demo
```

**Nota**: `labels.includeSelectors: true` propaga labels a todos los recursos.

### 4. Componente de Aplicación

**Path**: `K8s/<nombre-stack>/<nombre-componente>/`

#### Opción A: Helm Chart

**Chart.yaml**:
```yaml
apiVersion: v2
name: <nombre-componente>
version: <version>
```

**values.yaml**:
```yaml
# -- Description of parameter (helm-docs annotation)
parameterName: value

## @section Section Name
# -- Another parameter description
anotherParam: value
```

**Convención helm-docs**:
- Comentarios con `# --` se convierten en documentación
- `## @section` agrupa parámetros
- Regenerar con `task utils:docs:helm` después de cambios

**kustomization.yaml**:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

helmCharts:
  - name: <nombre-chart>
    repo: <helm-repo-url>
    version: <version>
    releaseName: <release-name>
    namespace: <nombre-namespace>
    valuesFile: values.yaml

resources:
  - <external-secrets-si-aplica>.yaml
```

**Ejemplo real** (K8s/cicd/sonarqube/kustomization.yaml):
```yaml
helmCharts:
  - name: sonarqube
    repo: https://SonarSource.github.io/helm-chart-sonarqube
    version: 2025.5.0
    releaseName: sonarqube
    namespace: cicd
    valuesFile: values.yaml
```

#### Opción B: Manifests Kubernetes

**kustomization.yaml**:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml
  # ... otros manifests
```

**Nota**: Manifests deben incluir labels estándar (ver siguiente sección).

### 5. README (RECOMENDADO)

**Path**: `K8s/<nombre-stack>/<nombre-componente>/README.md`

Documentar:
- **Propósito** del componente
- **Vault setup** si usa ExternalSecrets (path de secretos, properties)
- **Valores importantes** del Helm chart con explicaciones
- **Acceso post-despliegue**: URLs, credenciales default, comandos útiles
- **Troubleshooting** común

**Ejemplo**: Ver `K8s/cicd/sonarqube/README.md`, `K8s/backstage/dex/VAULT-SETUP.md`

## Convenciones Obligatorias

### Labels Estándar (OBLIGATORIO en todos los recursos)

```yaml
labels:
  app.kubernetes.io/part-of: idp
  owner: platform-team
  business-unit: infrastructure
  environment: demo
```

**Referencia completa**: `Docs/src/content/docs/reference/labels-standard.md`

### Resource Limits (OBLIGATORIO en workloads)

Todos los Deployments/StatefulSets deben especificar:
```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

**Excepción**: cilium-agent intencionalmente sin limits.
**Unidades**: CPU en millicores (`500m`), memory en `Mi/Gi`.

### Sync Wave Annotations

Orden de despliegue:
- **Namespace**: `-2` (primero)
- **Infrastructure/Secrets**: `-1` (segundo)
- **Aplicaciones**: `0` (default, tercero)

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
```

### Atomic Commits

Un cambio lógico por commit para `git bisect` efectivo.

## Integración con Taskfile

### Agregar nuevo stack a Task/stacks.yaml

```yaml
tasks:
  <nombre-stack>:
    desc: 'Deploy <Descripción Stack> via ArgoCD'
    dir: K8s/<nombre-stack>
    preconditions:
      - sh: command -v envsubst
        msg: 'envsubst is required but not installed'
      - sh: command -v kubectl
        msg: 'kubectl is required but not installed'
    env:
      REPO_URL: '{{.REPO_URL}}'
      TARGET_REVISION: '{{.TARGET_REVISION}}'
    cmds:
      - envsubst < applicationset-<nombre-stack>.yaml | kubectl apply -f -
```

### Agregar fuse a config.toml

```toml
[fuses]
<nombre-stack> = true
```

### Agregar fuse a Taskfile.yaml

```yaml
vars:
  FUSE_<NOMBRE_STACK>:
    sh: |
      v=$(./Scripts/config-get.sh fuses.<nombre-stack> '{{.CONFIG_FILE}}' 2>/dev/null || true); [ -z "$v" ] && v=true; echo "$v"
```

### Agregar condición a stacks:deploy

En `Task/stacks.yaml`, task `deploy`, agregar:
```yaml
- |
  if [ "{{.FUSE_<NOMBRE_STACK>}}" != "false" ]; then
    task stacks:<nombre-stack> || exit 1
  else
    echo "Skipping <nombre-stack>"
  fi
```

## Checklist Post-Creación

1. **Quality gates**:
   - `task quality:lint` (YAML, shell, markdown)
   - `task quality:validate` (kustomize build + kubeval)

2. **Regenerar docs** si creaste Helm chart:
   - `task utils:docs:helm` (helm-docs)
   - `task utils:docs:metadata` (Chart.yaml metadata)

3. **Verificar config efectiva**:
   - `task utils:config:print`

4. **Test despliegue**:
   - `task stacks:<nombre-stack>` (solo tu stack)
   - O con fuse: editar `config.toml` fuses, `task stacks:deploy`

5. **Commits atómicos** con mensajes descriptivos

## Debugging con config.toml

### Aislar problemas de stack
```toml
[fuses]
policies = false       # Deshabilitar Kyverno si bloquea
observability = false  # Reducir uso de recursos
cicd = false
security = false
backstage = false
```

### Probar con fork/branch diferente
```toml
[git]
repo_url = "https://github.com/tu-fork/idp-blueprint.git"
target_revision = "feature-branch"
```

### Reducir timeouts para fast-fail
```toml
[operational]
kubectl_timeout = "60s"

[argocd]
sync_timeout = "2m"
retry_limit = 3
```

### Probar con versiones específicas
```toml
[versions]
cilium = "1.18.1"      # Downgrade para probar bug fix
argocd = "8.5.0"
```

### Acceso local personalizado
```toml
[network]
lan_ip = "192.168.1.100"  # IP fija para testing
nodeport_http = 31080      # Evitar conflicto con otros servicios
nodeport_https = 31443
```

## Test Manual de Nuevos Componentes

1. **Desarrollo iterativo**:
   - Deshabilitar todos los stacks excepto el tuyo en fuses
   - `task destroy && task deploy` para ciclo completo
   - O `kubectl delete -f applicationset-<stack>.yaml` y reaplica

2. **Validar Helm values**:
   - `helm template <release> <chart> -f values.yaml > rendered.yaml`
   - Inspeccionar rendered.yaml antes de desplegar

3. **Validar Kustomize**:
   - `kustomize build K8s/<stack>/<componente>/ > output.yaml`
   - Verificar labels, annotations, resource limits

4. **Monitorear despliegue**:
   - `kubectl get applications -n argocd -w`
   - `kubectl get pods -n <namespace> -w`
   - ArgoCD UI: `http://argocd.<LAN_IP>.nip.io`

5. **Logs y eventos**:
   - `kubectl logs -n <namespace> <pod>`
   - `kubectl describe pod -n <namespace> <pod>`
   - `kubectl get events -n <namespace> --sort-by='.lastTimestamp'`
