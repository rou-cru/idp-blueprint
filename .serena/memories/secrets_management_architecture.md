# Secrets Management Architecture: Demo vs Production Balance

## Visión General

El proyecto implementa un **sistema híbrido de secrets management** que balancea dos filosofías:
1. **Demo-friendly**: `config.toml` con passwords conocidas para facilitar testing local
2. **Production-ready**: Vault + External Secrets Operator (ESO) como flujo estándar

**Decisión arquitectónica crítica**: Los secrets NUNCA van directamente a Git. Vault es la single source of truth, config.toml solo proporciona valores iniciales que se cargan a Vault.

### Stack de Secrets

```
config.toml (demo passwords)
  ↓
vault-generate.sh (seeding script)
  ↓
HashiCorp Vault (secrets backend)
  ↓
External Secrets Operator (sync controller)
  ↓
SecretStore (namespace-scoped Vault connection)
  ↓
ExternalSecret (declarative secret sync)
  ↓
Kubernetes Secret (in-cluster secret)
  ↓
Application Pods (consume via env/volume)
```

## Componentes del Sistema

### 1. HashiCorp Vault

**Archivo**: `IT/vault/values.yaml`

#### Configuración Demo (NO PARA PRODUCCIÓN)

```yaml
server:
  standalone:
    enabled: true
    config: |
      ui = true
      storage "raft" {
        path    = "/vault/data"
        node_id = "vault-0"
      }
      listener "tcp" {
        address         = "0.0.0.0:8200"
        tls_disable     = "true"      # ⚠️ DEMO ONLY
        telemetry {
          unauthenticated_metrics_access = true
        }
      }
```

**⚠️ Demo Decisions**:
- **TLS disabled**: Vault escucha HTTP (no HTTPS)
  - **Razón**: Simplifica demo, evita cert management interno
  - **Prod**: `tls_disable = "false"` + cert-manager certificate
- **Standalone mode**: Single pod (no HA)
  - **Razón**: Recursos limitados en laptop
  - **Prod**: HA mode con 3+ pods + Raft clustering
- **Single unseal key**: `key-shares=1, key-threshold=1`
  - **Razón**: Auto-unseal sin complejidad
  - **Prod**: Shamir key shares (5 shares, threshold 3) o auto-unseal con Cloud KMS

**Storage**:
```yaml
dataStorage:
  enabled: true
  size: 1Gi        # Demo: suficiente para secrets básicos
                   # Prod: 10Gi+ dependiendo de escala
```

#### Secrets Engines Habilitados

**Script**: `Scripts/vault-init.sh:130-141`

```bash
# KV v2 para static secrets (passwords, tokens, API keys)
vault secrets enable -path=secret kv-v2

# Database engine para dynamic DB credentials
vault secrets enable database

# Transit engine para encryption-as-a-service
vault secrets enable transit
```

**KV v2 Structure** (usado en proyecto):
```
secret/
├── argocd/
│   └── admin
│       └── admin.password (bcrypt hash)
├── grafana/
│   └── admin
│       └── admin-password (plaintext)
├── sonarqube/
│   ├── admin
│   │   └── password
│   └── monitoring
│       └── passcode
├── backstage/
│   ├── app
│   │   ├── backendSecret
│   │   └── dexClientSecret
│   └── postgres
│       ├── adminPassword
│       └── appPassword
└── docker/
    └── registry
        ├── registry (URL)
        ├── username
        └── password
```

### 2. Vault Initialization Flow

**Script**: `Scripts/vault-init.sh`

#### Step 1: Initialize Vault (One-time)

```bash
vault operator init \
  -key-shares=1 \
  -key-threshold=1 \
  -format=json
# Output: unseal_keys_b64[0], root_token
```

**Resultado**:
- Unseal key: Stored in K8s Secret `vault-init-keys`
- Root token: Stored in K8s Secret `vault-init-keys`

**⚠️ Security Note**: En prod, NO almacenar root token en K8s. Usar external secret manager (AWS Secrets Manager, Azure Key Vault, etc.)

#### Step 2: Unseal Vault

```bash
vault operator unseal $UNSEAL_KEY
```

**Auto-unseal en reinicio**: Script detecta si Vault sealed y auto-unseal con key desde secret.

#### Step 3: Configure Kubernetes Auth

```bash
vault auth enable kubernetes

vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc:443"
```

**Flujo de autenticación**:
```
Pod with ServiceAccount
  ↓ (JWT token)
Vault Kubernetes Auth
  ↓ (validates with K8s API)
Vault Role (eso-{namespace}-role)
  ↓ (policy attachment)
Vault Policy (eso-policy)
  ↓ (permissions)
Secret Access
```

#### Step 4: Create Roles per Namespace

**Script**: `Scripts/vault-init.sh:156-196`

```bash
# Ejemplo: ArgoCD namespace
vault write auth/kubernetes/role/eso-argocd-role \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=argocd \
  policies=eso-policy \
  audience=vault \
  ttl=24h
```

**Roles creados**:
- `eso-argocd-role` → namespace `argocd`, SA `external-secrets`
- `eso-cicd-role` → namespace `cicd`, SA `external-secrets`
- `eso-observability-role` → namespace `observability`, SA `external-secrets`
- `eso-backstage-role` → namespace `backstage`, SA `external-secrets`

**Policy** (`eso-policy`):
```hcl
path "secret/data/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "secret/metadata/*" {
  capabilities = ["list", "read"]
}
```

**⚠️ Security**: Policy permite acceso a TODO `secret/*`. En prod, crear policies granulares por namespace:
```hcl
# eso-argocd-policy (restrictivo)
path "secret/data/argocd/*" {
  capabilities = ["read"]
}
```

### 3. Secret Generation (Seeding)

**Script**: `Scripts/vault-generate.sh`

#### Usage Pattern

```bash
./vault-generate.sh <vault-path> <key-name> [password] [format] [hashing]
```

**Argumentos**:
- `vault-path`: KV path (e.g., `secret/argocd/admin`)
- `key-name`: Property name (e.g., `admin.password`)
- `password`: Valor (empty = random generation)
- `format`: `base64` o `hex` (para random generation)
- `hashing`: `bcrypt` o `none`

#### Random Generation (Production-safe)

```bash
# Genera 32-byte random password via Vault's crypto engine
vault write -field=random_bytes "sys/tools/random/32" "format=base64"
```

**Ventaja vs openssl/pwgen**: Usa Vault's CSPRNG (cryptographically secure)

#### Hashing (ArgoCD Case)

```bash
# ArgoCD requires bcrypt hash, not plaintext
htpasswd -nbBC 10 admin "$password" | cut -d: -f2
```

**Algoritmo**: bcrypt con cost factor 10

#### Storage Strategy: Patch-first

**Script**: `Scripts/vault-generate.sh:171-188`

```bash
# Try patch (preserves other keys)
vault kv patch secret/docker/registry "username=myuser"

# If fails (secret doesn't exist), use put
vault kv put secret/docker/registry "username=myuser"
```

**Razón**: Permite múltiples keys en mismo path sin sobrescribir:
```
secret/docker/registry
├── registry: "docker.io"      (added first)
├── username: "user"           (patched)
└── password: "pass"           (patched)
```

### 4. Task: vault:generate-secrets

**Archivo**: `Task/bootstrap.yaml:225-287`

#### Secrets Matrix

```yaml
SECRETS:
  # ArgoCD admin (bcrypt for ArgoCD compatibility)
  - path: 'secret/argocd/admin'
    key: 'admin.password'
    var: 'ARGOCD_ADMIN_PASSWORD'
    enc: 'base64'
    hash: 'bcrypt'
  
  # Grafana admin (plaintext)
  - path: 'secret/grafana/admin'
    key: 'admin-password'
    var: 'GRAFANA_ADMIN_PASSWORD'
    enc: 'base64'
    hash: 'none'
  
  # SonarQube admin (plaintext)
  - path: 'secret/sonarqube/admin'
    key: 'password'
    var: 'SONARQUBE_ADMIN_PASSWORD'
    enc: 'base64'
    hash: 'none'
  
  # SonarQube monitoring (hex for token-like)
  - path: 'secret/sonarqube/monitoring'
    key: 'passcode'
    var: 'SONARQUBE_MONITORING_PASSCODE'
    enc: 'hex'
    hash: 'none'
  
  # Docker registry credentials
  - path: 'secret/docker/registry'
    key: 'registry'
    var: 'DOCKER_REGISTRY_URL'
    enc: 'base64'
    hash: 'none'
  - path: 'secret/docker/registry'
    key: 'username'
    var: 'DOCKER_REGISTRY_USERNAME'
    enc: 'base64'
    hash: 'none'
  - path: 'secret/docker/registry'
    key: 'password'
    var: 'DOCKER_REGISTRY_PASSWORD'
    enc: 'base64'
    hash: 'none'
  
  # Backstage secrets (random generation if var empty)
  - path: 'secret/backstage/app'
    key: 'backendSecret'
    var: ''                              # Empty = random
    enc: 'base64'
    hash: 'none'
  - path: 'secret/backstage/app'
    key: 'dexClientSecret'
    var: 'BACKSTAGE_DEX_CLIENT_SECRET'
    enc: 'base64'
    hash: 'none'
  - path: 'secret/backstage/postgres'
    key: 'adminPassword'
    var: ''                              # Empty = random
    enc: 'base64'
    hash: 'none'
  - path: 'secret/backstage/postgres'
    key: 'appPassword'
    var: ''                              # Empty = random
    enc: 'base64'
    hash: 'none'
```

#### Demo vs Production Decisión

**Demo mode** (`config.toml` con valores):
```toml
[passwords]
argocd_admin = "argo"
grafana_admin = "graf"
sonarqube_admin = "Sonar-Secret-123"
```

**Flujo**:
1. Taskfile vars read config.toml
2. `vault-generate.sh` recibe valor desde var
3. Script usa valor provisto (NO random)
4. Secret se guarda en Vault

**Production mode** (passwords vacíos en config.toml):
```toml
[passwords]
argocd_admin = ""
grafana_admin = ""
sonarqube_admin = ""
```

**Flujo**:
1. Taskfile vars son empty strings
2. `vault-generate.sh` detecta empty
3. Script genera random 32-byte password via Vault
4. Secret se guarda en Vault

**Backstage secrets** (SIEMPRE random):
```yaml
- path: 'secret/backstage/app'
  key: 'backendSecret'
  var: ''              # Hardcoded empty, siempre random
```

**Razón**: Tokens de sesión deben ser impredecibles, incluso en demo.

### 5. config.toml: Demo-Only Initial Values

**Archivo**: `config.toml:51-60`

```toml
[passwords]
# Empty strings instruct Vault helpers to generate random secrets.
argocd_admin = "argo"
grafana_admin = "graf"
# SonarQube admin password requires a minimum of 12 characters and at least one uppercase letter.
sonarqube_admin = "Sonar-Secret-123"
sonarqube_monitoring = "sonar"
kyverno_admin = "kyver"
vault_admin = "vault"
backstage_dex_client = "backstage-demo-secret"
```

**⚠️ IMPORTANTE**: 
- **NO son secrets reales**: Solo valores de seeding para Vault
- **NO se usan directamente**: Apps leen desde Vault via ESO
- **NO commitear passwords reales**: config.toml es público en Git
- **Comentario clave**: "Empty strings instruct Vault helpers to generate random secrets"

**Uso**:
1. Developer clona repo
2. `task deploy` lee config.toml
3. Vault se inicializa con estos valores conocidos
4. Developer puede login con `argo` / `graf` / etc.
5. **En producción**: Cambiar todos a `""` para random generation

### 6. External Secrets Operator (ESO)

**Deployment**: `IT/external-secrets/values.yaml`

#### Configuración

```yaml
priorityClassName: platform-infrastructure

installCRDs: true
replicas: 1

resources:
  requests:
    cpu: 250m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 1Gi

concurrent: 5        # Concurrent ExternalSecret reconciliations
```

**Webhook + cert-manager**:
```yaml
webhook:
  certManager:
    enabled: true
    addInjectorAnnotations: true
    cert:
      issuerRef:
        kind: ClusterIssuer
        name: ca-issuer
      duration: "2160h"       # 90 days
      renewBefore: "720h"     # 30 days before expiry
```

**Razón cert-manager**: ESO webhook necesita TLS cert para admission control. Cert-manager auto-renueva.

### 7. ServiceAccount Strategy (Per-Namespace)

**Pattern**: Cada namespace con secrets tiene su propio ServiceAccount `external-secrets`

**Ejemplos**:
- `IT/serviceaccounts/eso-argocd.yaml` → namespace `argocd`
- `K8s/cicd/infrastructure/eso-cicd.yaml` → namespace `cicd`
- `K8s/observability/infrastructure/eso-observability.yaml` → namespace `observability`
- `K8s/backstage/infrastructure/eso-backstage.yaml` → namespace `backstage`

**Template**:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-secrets
  namespace: <namespace>
  labels:
    app.kubernetes.io/name: serviceaccount
    app.kubernetes.io/instance: eso-<namespace>
    app.kubernetes.io/component: secret-sync
    app.kubernetes.io/part-of: idp
```

**⚠️ Nombre fijo**: DEBE ser `external-secrets` (referenciado en Vault role)

**RBAC**: ESO operator crea ClusterRole que permite SA `external-secrets` leer secrets en su namespace.

### 8. SecretStore (Namespace-Scoped)

**Pattern**: Un SecretStore por namespace, apuntando a Vault con role específico

**Ejemplo**: `K8s/cicd/infrastructure/cicd-secretstore.yaml`

```yaml
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: cicd
  namespace: cicd
  annotations:
    argocd.argoproj.io/sync-wave: "-1"    # Deploy before ExternalSecrets
spec:
  retrySettings:
    maxRetries: 5
    retryInterval: "10s"
  provider:
    vault:
      server: "http://vault.vault-system.svc.cluster.local:8200"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "eso-cicd-role"           # Vault role específico
          serviceAccountRef:
            name: external-secrets
            audiences:
              - vault
```

**Sync wave `-1`**: SecretStore debe existir antes que ExternalSecrets que lo referencian.

**Service URL**: `http://vault.vault-system.svc.cluster.local:8200`
- HTTP (no HTTPS) - demo decision
- Cluster-internal DNS
- Prod: `https://vault.vault-system.svc.cluster.local:8200` + TLS cert validation

**Role naming**: `eso-{namespace}-role` convention
- Permite granular permissions per namespace
- Facilitates least-privilege access

### 9. ExternalSecret (Declarative Sync)

**Pattern**: Sync specific Vault paths to Kubernetes Secrets

#### Example 1: Simple Sync (Owner)

**Archivo**: `K8s/observability/kube-prometheus-stack/grafana-admin-externalsecret.yaml`

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: grafana-admin-password
  namespace: observability
spec:
  refreshInterval: 1h              # Re-sync every hour
  secretStoreRef:
    kind: SecretStore
    name: observability            # References SecretStore in same namespace
  target:
    name: grafana-admin-password   # K8s Secret name
    creationPolicy: Owner          # ESO owns this secret
  data:
    - secretKey: admin-password    # Key in K8s Secret
      remoteRef:
        key: secret/grafana/admin  # Vault KV path (v2 adds /data/)
        property: admin-password   # Property within Vault secret
```

**creationPolicy: Owner**:
- ESO creates secret if doesn't exist
- ESO updates secret on Vault changes
- ESO deletes secret if ExternalSecret deleted
- **Use case**: New secrets managed entirely by ESO

#### Example 2: Merge Policy (Preserve Existing Keys)

**Archivo**: `IT/external-secrets/argocd-admin-externalsecret.yaml`

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: argocd-admin-password
  namespace: argocd
  annotations:
    argocd.argoproj.io/compare-options: IgnoreExtraneous
    argocd.argoproj.io/sync-options: Prune=false
spec:
  refreshInterval: 3m
  secretStoreRef:
    kind: SecretStore
    name: vault-backend
  target:
    name: argocd-secret            # Existing ArgoCD secret
    creationPolicy: Merge          # CRITICAL: Preserves other keys
    deletionPolicy: Retain         # Preserve secret if ExternalSecret deleted
  data:
    - secretKey: admin.password
      remoteRef:
        key: secret/data/argocd/admin
        property: admin.password
```

**creationPolicy: Merge** (CRITICAL):
- ESO updates ONLY `admin.password` key
- Preserves `server.secretkey` (auto-generated by ArgoCD)
- **Problema sin Merge**: ArgoCD regenera `server.secretkey` → sessions invalidadas
- **Use case**: Secrets with mixed ownership (ESO + application)

**deletionPolicy: Retain**:
- K8s Secret persists if ExternalSecret deleted
- **Use case**: Protect against accidental ExternalSecret deletion

**ArgoCD annotations**:
- `IgnoreExtraneous`: ArgoCD ignores keys not in Git (server.secretkey)
- `Prune=false`: ArgoCD won't delete secret even if ExternalSecret removed from Git

#### Example 3: Multiple Keys from Same Path

**Archivo**: `K8s/backstage/backstage/backstage-app-externalsecret.yaml`

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: backstage-app-secrets
  namespace: backstage
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: backstage
    kind: SecretStore
  target:
    name: backstage-app-secrets
    creationPolicy: Owner
  data:
    - secretKey: BACKEND_SECRET
      remoteRef:
        key: secret/backstage/app
        property: backendSecret
    - secretKey: POSTGRES_PASSWORD
      remoteRef:
        key: secret/backstage/postgres
        property: appPassword
    - secretKey: DEX_CLIENT_SECRET
      remoteRef:
        key: secret/backstage/app
        property: dexClientSecret
```

**Multiple data entries**:
- Single ExternalSecret syncs multiple Vault paths
- Resulting K8s Secret has 3 keys: `BACKEND_SECRET`, `POSTGRES_PASSWORD`, `DEX_CLIENT_SECRET`
- **Use case**: Application needs secrets from multiple Vault locations

### 10. Consumption Patterns

#### Pattern A: Environment Variables

**Backstage values.yaml**:
```yaml
backstage:
  extraEnvVarsSecrets:
    - backstage-app-secrets    # References ExternalSecret target name
```

**Result**: Pod gets env vars from secret keys:
```yaml
env:
  - name: BACKEND_SECRET
    valueFrom:
      secretKeyRef:
        name: backstage-app-secrets
        key: BACKEND_SECRET
```

#### Pattern B: Volume Mounts (SonarQube)

**SonarQube values.yaml**:
```yaml
setAdminPassword:
  enabled: true
  passwordSecretName: sonarqube-admin-credentials
  passwordSecretKey: password
  currentPasswordSecretName: sonarqube-admin-credentials
  currentPasswordSecretKey: currentPassword
```

**Chart behavior**: Mounts secret to init container, uses to set admin password via API.

#### Pattern C: Docker Registry Secret

**Archivo**: `K8s/cicd/argo-workflows/docker-credentials-externalsecret.yaml`

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: docker-credentials
  namespace: cicd
spec:
  target:
    name: docker-credentials
    creationPolicy: Owner
    template:
      type: kubernetes.io/dockerconfigjson   # Special type
      data:
        .dockerconfigjson: |
          {
            "auths": {
              "{{ .registry }}": {
                "username": "{{ .username }}",
                "password": "{{ .password }}",
                "auth": "{{ printf "%s:%s" .username .password | b64enc }}"
              }
            }
          }
  data:
    - secretKey: registry
      remoteRef:
        key: secret/docker/registry
        property: registry
    - secretKey: username
      remoteRef:
        key: secret/docker/registry
        property: username
    - secretKey: password
      remoteRef:
        key: secret/docker/registry
        property: password
```

**Template feature**: ESO can template secret data using fetched values.

**Use case**: Create `kubernetes.io/dockerconfigjson` from individual Vault keys.

### 11. Deployment Order & Sync Waves

**Critical order** (enforced via sync waves):

```
-2: Namespaces (governance/)
-1: Infrastructure (ServiceAccounts, SecretStores)
 0: ExternalSecrets (default)
 1: Applications (consume secrets)
```

**Example**: `K8s/cicd/infrastructure/cicd-secretstore.yaml`

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
```

**Ensures**:
1. Namespace exists
2. ServiceAccount `external-secrets` exists
3. SecretStore configured
4. ExternalSecrets can sync
5. Applications start with secrets ready

### 12. Secrets Lifecycle

#### Initial Deployment

```
1. task deploy
   ↓
2. Vault deployed (IT/vault)
   ↓
3. vault-init.sh
   - Initialize Vault
   - Unseal Vault
   - Configure Kubernetes auth
   - Create roles (eso-{namespace}-role)
   ↓
4. vault-generate-secrets
   - Read config.toml passwords
   - Generate/store in Vault
   ↓
5. ESO deployed (IT/external-secrets)
   ↓
6. Per-namespace setup (via ArgoCD)
   - ServiceAccount external-secrets
   - SecretStore
   - ExternalSecrets
   ↓
7. ESO syncs Vault → K8s Secrets
   ↓
8. Applications consume secrets
```

#### Secret Rotation

**Manual rotation**:
```bash
# Update in Vault
kubectl exec -n vault-system vault-0 -- \
  env VAULT_TOKEN="$ROOT_TOKEN" \
  vault kv put secret/grafana/admin admin-password="NewPassword123"

# ESO auto-syncs within refreshInterval (default 1h)
# Or force refresh:
kubectl annotate externalsecret grafana-admin-password \
  -n observability \
  force-sync="$(date +%s)"
```

**Automated rotation** (not implemented, production consideration):
```yaml
# Using Vault's database engine for dynamic credentials
vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@postgres:5432/mydb" \
  allowed_roles="readonly,readwrite"

vault write database/roles/readonly \
  db_name=postgresql \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="1h" \
  max_ttl="24h"
```

**ESO integration** (requires DatabaseSecret CRD, not used in demo):
```yaml
apiVersion: external-secrets.io/v1alpha1
kind: DatabaseSecret
metadata:
  name: postgres-dynamic
spec:
  backend: vault
  vaultMountPath: database
  vaultRole: readonly
```

#### Secret Deletion

**ExternalSecret deleted** (creationPolicy: Owner):
- K8s Secret deleted
- Vault secret remains

**ExternalSecret deleted** (deletionPolicy: Retain):
- K8s Secret remains
- Useful for protecting against accidental deletion

**Vault secret deleted**:
- ESO marks ExternalSecret as Failed
- K8s Secret remains with last known value
- **Monitoring**: Check ExternalSecret status

```bash
kubectl get externalsecrets -A
# Look for Status: SecretSyncedError
```

### 13. Security Considerations

#### Demo vs Production Decisions

| Aspect | Demo | Production |
|--------|------|-----------|
| Vault TLS | Disabled (`tls_disable=true`) | Enabled with cert-manager cert |
| Vault Mode | Standalone (single pod) | HA (3+ pods, Raft clustering) |
| Unseal | Auto-unseal with K8s Secret | Auto-unseal with Cloud KMS (AWS/GCP/Azure) |
| Root Token | Stored in K8s Secret | Never stored, use temporary tokens |
| Passwords | Known values in config.toml | Empty config.toml, random generation |
| Vault Policy | Broad `secret/*` access | Granular per-namespace policies |
| Secret Rotation | Manual | Automated via Vault dynamic secrets |
| Audit Logging | File audit (`/vault/logs/audit.log`) | External SIEM (Splunk, ELK) |
| Network Access | ClusterIP, accessible from all pods | NetworkPolicy to restrict access |

#### Production Hardening Checklist

**Vault**:
```yaml
# HA mode with Raft
server:
  ha:
    enabled: true
    replicas: 3
    raft:
      enabled: true
      config: |
        ui = true
        listener "tcp" {
          tls_cert_file = "/vault/tls/tls.crt"
          tls_key_file  = "/vault/tls/tls.key"
        }
  # Auto-unseal with Cloud KMS
  seal:
    awskms:
      region: "us-west-2"
      kms_key_id: "arn:aws:kms:..."
```

**Policies**:
```hcl
# eso-argocd-policy (restrictive)
path "secret/data/argocd/*" {
  capabilities = ["read"]
}

# eso-cicd-policy (write for CI/CD)
path "secret/data/cicd/*" {
  capabilities = ["create", "read", "update"]
}
```

**NetworkPolicy**:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: vault-access
  namespace: vault-system
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: vault
  ingress:
    # Allow only from ESO pods
    - from:
        - namespaceSelector:
            matchLabels:
              name: argocd
          podSelector:
            matchLabels:
              app.kubernetes.io/name: external-secrets
```

**Secret Scanning** (pre-commit hook):
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/trufflesecurity/trufflehog
    rev: v3.63.0
    hooks:
      - id: trufflehog
        args: ['--regex', '--entropy=True']
```

**Encryption at Rest** (Kubernetes):
```yaml
# EncryptionConfiguration
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: <base64 encoded secret>
      - identity: {}
```

### 14. Monitoring & Observability

#### Vault Metrics

**ServiceMonitor**: `IT/vault/values.yaml:95-101`

```yaml
serviceMonitor:
  enabled: true
  interval: 60s
  scrapeTimeout: 40s
```

**Metrics endpoint**: `http://vault:8200/v1/sys/metrics`

**Key metrics**:
- `vault_core_unsealed` - Vault seal status (0=sealed, 1=unsealed)
- `vault_runtime_alloc_bytes` - Memory usage
- `vault_token_count` - Active tokens
- `vault_secret_kv_count` - Number of secrets

**Prometheus rules** (not implemented, prod consideration):
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: vault-alerts
spec:
  groups:
    - name: vault
      rules:
        - alert: VaultSealed
          expr: vault_core_unsealed == 0
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "Vault is sealed"
        - alert: VaultDown
          expr: up{job="vault"} == 0
          for: 5m
          labels:
            severity: critical
```

#### ESO Metrics

**ServiceMonitor**: `IT/external-secrets/values.yaml:123-131`

```yaml
serviceMonitor:
  enabled: true
  interval: 60s
  scrapeTimeout: 40s
  honorLabels: true
```

**Metrics endpoint**: `http://external-secrets-webhook:8080/metrics`

**Key metrics**:
- `externalsecret_status_condition` - ExternalSecret status (Ready/Failed)
- `externalsecret_sync_calls_total` - Sync attempts
- `externalsecret_sync_calls_error` - Failed syncs
- `externalsecret_reconcile_duration` - Sync latency

**Grafana Dashboard** (example queries):
```promql
# ExternalSecrets in error state
count(externalsecret_status_condition{condition="Ready",status="False"})

# Sync error rate
rate(externalsecret_sync_calls_error[5m])

# Sync duration P95
histogram_quantile(0.95, rate(externalsecret_reconcile_duration_bucket[5m]))
```

#### SLO: Secret Sync Availability

**Archivo**: `K8s/observability/slo/secrets-sync-slo.yaml`

```yaml
apiVersion: pyrra.dev/v1alpha1
kind: ServiceLevelObjective
metadata:
  name: secrets-sync-availability
  namespace: observability
spec:
  target: "99.5"        # 99.5% availability
  window: 30d
  indicator:
    ratio:
      errors:
        metric: externalsecret_sync_calls_error
      total:
        metric: externalsecret_sync_calls_total
```

**Monitoring**: Pyrra generates alerts for burn rate

### 15. Troubleshooting

#### Issue 1: ExternalSecret Stuck in "SecretSyncedError"

**Síntoma**: `kubectl get externalsecret` shows `SecretSyncedError`

**Diagnosis**:
```bash
# Check ExternalSecret status
kubectl describe externalsecret <name> -n <namespace>

# Common errors:
# - "secret not found" → Vault path doesn't exist
# - "permission denied" → Role lacks policy
# - "connection refused" → Vault unreachable
```

**Fix for "secret not found"**:
```bash
# Verify Vault secret exists
kubectl exec -n vault-system vault-0 -- \
  env VAULT_TOKEN="$ROOT_TOKEN" \
  vault kv get secret/argocd/admin

# If missing, re-run seeding
task vault:generate-secrets
```

**Fix for "permission denied"**:
```bash
# Check Vault role
kubectl exec -n vault-system vault-0 -- \
  env VAULT_TOKEN="$ROOT_TOKEN" \
  vault read auth/kubernetes/role/eso-argocd-role

# Verify policy allows path
kubectl exec -n vault-system vault-0 -- \
  env VAULT_TOKEN="$ROOT_TOKEN" \
  vault policy read eso-policy
```

**Fix for "connection refused"**:
```bash
# Check Vault pod
kubectl get pod -n vault-system

# Check Vault unsealed
kubectl exec -n vault-system vault-0 -- vault status
# sealed=false?

# If sealed, unseal
task vault:init
```

#### Issue 2: Vault Sealed After Restart

**Síntoma**: Vault pod running but `vault status` shows `sealed=true`

**Auto-unseal**:
```bash
# vault-init.sh handles this
./Scripts/vault-init.sh
```

**Manual unseal**:
```bash
UNSEAL_KEY=$(kubectl get secret vault-init-keys -n vault-system -o jsonpath='{.data.unseal-key}' | base64 -d)
kubectl exec -n vault-system vault-0 -- vault operator unseal "$UNSEAL_KEY"
```

#### Issue 3: Application Can't Read Secret

**Síntoma**: Pod crashloop, logs show "secret not found"

**Diagnosis**:
```bash
# Check K8s Secret exists
kubectl get secret <secret-name> -n <namespace>

# Check secret has correct keys
kubectl get secret <secret-name> -n <namespace> -o yaml

# Check ExternalSecret synced
kubectl get externalsecret -n <namespace>
```

**Fix**: Verify ExternalSecret `data[].secretKey` matches what application expects.

#### Issue 4: Password Changed but App Still Uses Old

**Causa**: Secret cached in pod, not reloaded

**Fix**:
```bash
# Update Vault
kubectl exec -n vault-system vault-0 -- \
  env VAULT_TOKEN="$ROOT_TOKEN" \
  vault kv put secret/grafana/admin admin-password="NewPass"

# Force ESO refresh
kubectl annotate externalsecret grafana-admin-password \
  -n observability \
  force-sync="$(date +%s)"

# Restart pods to reload secret
kubectl rollout restart deployment prometheus-grafana -n observability
```

**Production solution**: Use Reloader (https://github.com/stakater/Reloader)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    reloader.stakater.com/auto: "true"   # Auto-restart on secret change
```

#### Issue 5: ESO Webhook Certificate Expired

**Síntoma**: `kubectl get validatingwebhookconfiguration` shows cert expired

**Fix**: cert-manager auto-renews, but if stuck:
```bash
# Delete webhook cert
kubectl delete certificate external-secrets-webhook -n external-secrets

# cert-manager recreates
kubectl get certificate -n external-secrets -w
```

### 16. Adding New Secret to Vault

#### Step-by-step

**1. Add to vault:generate-secrets matrix**

Edit `Task/bootstrap.yaml:225-287`:
```yaml
SECRETS:
  - path: 'secret/myapp/credentials'
    key: 'api-key'
    var: 'MYAPP_API_KEY'      # From config.toml or empty for random
    enc: 'base64'
    hash: 'none'
```

**2. Add to config.toml** (optional, for demo):
```toml
[passwords]
myapp_api_key = "demo-api-key-123"
```

**3. Create Vault role** (if new namespace):

Edit `Scripts/vault-init.sh`, add:
```bash
kubectl exec -n "$NAMESPACE" vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" \
  vault write auth/kubernetes/role/eso-myapp-role \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=myapp \
  policies=eso-policy \
  audience=vault \
  ttl=24h
```

**4. Create namespace ServiceAccount**:
```yaml
# K8s/myapp/infrastructure/eso-myapp.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-secrets
  namespace: myapp
```

**5. Create SecretStore**:
```yaml
# K8s/myapp/infrastructure/myapp-secretstore.yaml
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: myapp
  namespace: myapp
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
spec:
  provider:
    vault:
      server: "http://vault.vault-system.svc.cluster.local:8200"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "eso-myapp-role"
          serviceAccountRef:
            name: external-secrets
            audiences:
              - vault
```

**6. Create ExternalSecret**:
```yaml
# K8s/myapp/myapp/credentials-externalsecret.yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: myapp-credentials
  namespace: myapp
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: SecretStore
    name: myapp
  target:
    name: myapp-credentials
    creationPolicy: Owner
  data:
    - secretKey: API_KEY
      remoteRef:
        key: secret/myapp/credentials
        property: api-key
```

**7. Deploy**:
```bash
task vault:generate-secrets   # Seeds Vault
task stacks:deploy            # ArgoCD deploys SecretStore + ExternalSecret
```

**8. Verify**:
```bash
# Check ExternalSecret synced
kubectl get externalsecret myapp-credentials -n myapp

# Check K8s Secret created
kubectl get secret myapp-credentials -n myapp -o yaml
```

### 17. Remediation Workflows

**Argo Workflows template**: `K8s/cicd/argo-workflows/workflow-templates/remediate-externalsecret-failure.yaml`

**Trigger**: Manual or via EventSource (SLO breach)

**Workflow**:
```yaml
steps:
  - name: delete-externalsecret
    container:
      image: bitnami/kubectl
      command: [kubectl, delete, externalsecret, "{{workflow.parameters.externalsecret-name}}", -n, "{{workflow.parameters.namespace}}"]
  
  - name: wait-for-resync
    container:
      image: bitnami/kubectl
      command: [sh, -c]
      args:
        - |
          kubectl wait --for=condition=Ready externalsecret/{{workflow.parameters.externalsecret-name}} \
            -n {{workflow.parameters.namespace}} \
            --timeout=120s
```

**Use case**: Auto-remediate stuck ExternalSecrets

### 18. Documentation per Service

Each service with secrets should have VAULT-SETUP.md:

**Template**: `K8s/backstage/dex/VAULT-SETUP.md`

```markdown
# Vault Setup for <Service>

## Secrets Required

### Path: `secret/<service>/<subpath>`

```bash
vault kv put secret/<service>/<subpath> \
  key1="value1" \
  key2="value2"
```

## Verification

```bash
vault kv get secret/<service>/<subpath>
kubectl get externalsecret <name> -n <namespace>
kubectl get secret <name> -n <namespace>
```

## Security Notes

> [!WARNING]
> Demo values shown. In production:
> - Generate random secrets (openssl rand -base64 32)
> - Rotate secrets regularly
> - Use secret manager (AWS Secrets Manager, etc.)
```

## Summary: Demo vs Production Philosophy

### Demo Philosophy (Current Implementation)

**Goal**: Developer can `git clone` → `task deploy` → working platform in minutes

**Decisions**:
- ✅ **config.toml with known passwords**: Developer can login immediately
- ✅ **Vault with TLS disabled**: No cert complexity
- ✅ **Single unseal key in K8s**: Auto-unseal without external dependencies
- ✅ **Broad Vault policies**: Simplifies initial setup
- ✅ **Vault UI enabled**: Visual debugging

**Trade-offs**:
- ❌ **Not production-secure**: Vault over HTTP, root token in cluster
- ❌ **No rotation**: Manual secret updates
- ❌ **No audit trail**: File-based audit log

### Production Philosophy (Future/Migration)

**Goal**: Enterprise-grade secrets management with zero-trust security

**Required changes**:
1. **Vault HA with TLS**
   - 3+ pods, Raft consensus
   - cert-manager certificates
   - LoadBalancer with HTTPS

2. **Cloud auto-unseal**
   - AWS KMS / GCP KMS / Azure Key Vault
   - Never store unseal keys

3. **External secret initialization**
   - Initial secrets from AWS Secrets Manager / Azure Key Vault
   - Vault seeds from external source, not config.toml

4. **Granular policies**
   - Per-namespace, per-service policies
   - Least-privilege access

5. **Dynamic secrets**
   - Database credentials with TTL
   - Cloud provider credentials via Vault

6. **Secret rotation**
   - Automated rotation workflows
   - Reloader for zero-downtime updates

7. **Audit & compliance**
   - External SIEM integration
   - Immutable audit logs
   - Secret access tracking

8. **Disaster recovery**
   - Vault snapshot backups
   - Multi-region replication

**Migration path**:
```bash
# Phase 1: Enable TLS
# Update IT/vault/values.yaml with TLS config
# Update SecretStores with https:// URLs

# Phase 2: Implement auto-unseal
# Configure Cloud KMS in Vault

# Phase 3: Empty config.toml passwords
# All secrets generated random

# Phase 4: Granular policies
# Update vault-init.sh with namespace-specific policies

# Phase 5: Dynamic secrets
# Implement database engine for PostgreSQL, MySQL

# Phase 6: External audit
# Ship audit logs to SIEM
```

### Key Takeaway

**The architecture is production-ready, the configuration is demo-optimized.**

Vault + ESO pattern is industry standard. Config decisions (TLS off, known passwords) are intentionally for demo. Flip config flags → production-grade system.
