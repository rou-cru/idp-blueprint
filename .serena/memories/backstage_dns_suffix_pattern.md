# Backstage DNS_SUFFIX Dynamic Configuration Pattern

## Problem Statement

Backstage requires dynamic DNS_SUFFIX values in multiple locations within YAML configuration files that are mounted as ConfigMaps. Unlike simple HTTPRoutes where `envsubst` can substitute values before deployment, Backstage's `app-config.override.yaml` contains complex multiline YAML with multiple URL references that must be substituted at runtime within the cluster.

## Technical Constraints

### Why Standard Approaches Fail

**Kustomize replacements**: Only work on YAML structure (field paths), not string interpolation within multiline text values.

**ArgoCD ApplicationSet patches**: Can patch simple values but cannot perform complex string substitution across multiline ConfigMap data.

**Helm templating**: Not applicable - Backstage chart expects pre-rendered config, not template variables.

**envsubst in Task pipeline**: Works for ApplicationSet itself but cannot substitute values inside manifests that ArgoCD generates from kustomize.

## Solution: Job-Renderer Pattern

### Architecture

```
1. Placeholder ConfigMap (sync-wave: -2)
   └─> Contains template with ${DNS_SUFFIX} placeholders
   
2. Vars ConfigMap (sync-wave: -2, patched by ApplicationSet)
   └─> Contains actual DNS_SUFFIX value from deployment

3. Renderer Job (sync-wave: -1, ArgoCD hook: Sync)
   └─> Reads vars ConfigMap
   └─> Reads template ConfigMap
   └─> Performs sed substitution
   └─> Creates/updates final ConfigMap

4. Application Pod (sync-wave: 0)
   └─> Mounts final ConfigMap with substituted values
```

### Implementation Components

#### vars-placeholder.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: idp-vars-backstage
  namespace: backstage
  annotations:
    argocd.argoproj.io/sync-wave: "-2"
data:
  DNS_SUFFIX: "placeholder"
```

**Purpose**: Git-tracked placeholder that ArgoCD patches via ApplicationSet.

#### templates/cm-tpl.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backstage-config-tpl
  annotations:
    argocd.argoproj.io/sync-wave: "-2"
data:
  app-config.override.yaml: |
    backend:
      baseUrl: https://backstage.${DNS_SUFFIX}
    auth:
      providers:
        oidc:
          production:
            metadataUrl: https://dex.${DNS_SUFFIX}/.well-known/openid-configuration
```

**Purpose**: Template with ${DNS_SUFFIX} placeholders for substitution.

#### job-renderer.yaml
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: backstage-config-renderer
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
    argocd.argoproj.io/hook: Sync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  template:
    spec:
      containers:
        - name: renderer
          image: bitnami/kubectl:latest
          command: ["/bin/bash", "-c"]
          args:
            - |
              export DNS_SUFFIX=$(cat /vars/DNS_SUFFIX)
              sed "s/\${DNS_SUFFIX}/$DNS_SUFFIX/g" /tpl/app-config.override.yaml > /tmp/config.yaml
              kubectl create configmap backstage-app-config-override \
                --from-file=app-config.override.yaml=/tmp/config.yaml \
                --dry-run=client -o yaml | kubectl apply -f -
          volumeMounts:
            - name: vars
              mountPath: /vars
            - name: tpl
              mountPath: /tpl
      volumes:
        - name: vars
          configMap:
            name: idp-vars-backstage
        - name: tpl
          configMap:
            name: backstage-config-tpl
```

**Key features**:
- Sync wave `-1`: Runs after ConfigMaps created, before application pods
- ArgoCD hook `Sync`: Re-executes on every sync
- Hook delete policy `HookSucceeded`: Cleans up job after success
- Uses `kubectl apply`: Idempotent, handles updates

#### ApplicationSet Patch
```yaml
kustomize:
  patches:
    - target:
        kind: ConfigMap
        name: idp-vars-backstage
      patch: |
        - op: replace
          path: /data/DNS_SUFFIX
          value: "${DNS_SUFFIX}"
```

**Purpose**: ApplicationSet substitutes `${DNS_SUFFIX}` from Task environment before applying.

## Deployment Flow

```
Task stacks:backstage
  ├─> Calculates DNS_SUFFIX dynamically
  ├─> Exports as env var
  └─> envsubst < applicationset-backstage.yaml | kubectl apply

ArgoCD
  ├─> Creates Application from ApplicationSet
  ├─> Patches idp-vars-backstage ConfigMap (wave -2)
  ├─> Creates backstage-config-tpl ConfigMap (wave -2)
  ├─> Runs backstage-config-renderer Job (wave -1)
  │   └─> Creates backstage-app-config-override ConfigMap
  └─> Deploys Backstage pod (wave 0)
      └─> Mounts backstage-app-config-override
```

## When to Use This Pattern

### ✅ Use Job-Renderer When:
- Application requires complex YAML config with multiple dynamic values
- Config is mounted as ConfigMap, not environment variables
- Values are multiline YAML/JSON structures
- Standard Kustomize/ArgoCD mechanisms insufficient

### ❌ Do NOT Use When:
- Simple HTTPRoute hostname substitution (use envsubst in Task)
- Environment variables (use ExternalSecrets or Kustomize patches)
- Single value substitution (use Kustomize replacements)
- Config can be passed via Helm values

## Examples in This Project

### Backstage (K8s/backstage/backstage/)
- **Config**: app-config.override.yaml with backend URLs, auth providers, CORS origins
- **Substitutions**: 5+ URLs with DNS_SUFFIX
- **Reason**: Backstage reads config directly from mounted file

### Dex (K8s/backstage/dex/)
- **Config**: dex config.yaml with issuer URL and redirect URIs
- **Substitutions**: 2 URLs with DNS_SUFFIX
- **Reason**: Dex OIDC configuration requires exact URLs

### Counter-Example: ArgoCD (IT/gateway/httproutes/)
- **Config**: HTTPRoute hostname
- **Substitution**: Single string value
- **Method**: envsubst in bootstrap:gateway:deploy task
- **Reason**: Simple enough for Task-level substitution

## Maintenance Notes

### Updating Templates
1. Edit `templates/cm-tpl.yaml` with new placeholders
2. Ensure all placeholders use `${VARIABLE}` syntax
3. Update job-renderer args if new variables needed
4. Commit template to Git

### Adding New Variables
1. Add to vars-placeholder.yaml (placeholder value)
2. Add to ApplicationSet patches (substitution)
3. Update job-renderer to export variable from ConfigMap
4. Update sed command to substitute new variable

### Troubleshooting

**Job fails with "ConfigMap not found"**:
- Check sync waves: vars-placeholder and cm-tpl must be wave `-2`
- Verify job is wave `-1`

**Substitution not applied**:
- Check job logs: `kubectl logs -n backstage job/backstage-config-renderer`
- Verify sed syntax in job args
- Confirm DNS_SUFFIX value in idp-vars-backstage ConfigMap

**ArgoCD shows drift**:
- Add ConfigMap to ignoreDifferences (data field changes by job)
- Job recreates ConfigMap on each sync (expected behavior)

## Alternative Considered: Init Container

Evaluated using init container in pod instead of separate job. Rejected because:
- DNS_SUFFIX not available as pod environment variable
- Would require downward API or additional complexity
- Job pattern is more GitOps-friendly (ArgoCD hook integration)
- Init container runs on every pod restart, not just sync
