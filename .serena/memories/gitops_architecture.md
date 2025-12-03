# GitOps Architecture

## Three-Layer Structure

### Layer 1: Bootstrap IT (Imperative)
- **Directory**: `IT/`
- **Method**: Direct Helm/Kubectl via `task deploy`
- **Components**: namespaces, cilium, cert-manager, vault, external-secrets, argocd, gateway
- **Rationale**: Bootstrap layer is imperative to avoid chicken-egg problem. ArgoCD cannot deploy itself.

### Layer 2: Platform Policies (Single Application)
- **Directory**: `Policies/`
- **Method**: ArgoCD Application (manual, not ApplicationSet)
- **Application Name**: `platform-policies`
- **Project**: `platform`
- **Namespace**: `kyverno-system`
- **Components**: Kyverno engine + Policy Reporter + ClusterPolicies
- **Sync Wave**: `"1"` (deploys before application stacks)

### Layer 3: Application Stacks (ApplicationSets)
- **Directory**: `K8s/`
- **Method**: ArgoCD ApplicationSets (App-of-Apps pattern)
- **Stacks**: observability, backstage, cicd, security, events
- **Pattern**: One ApplicationSet per stack → Multiple Applications via git directory generator

## ApplicationSet Pattern

All stacks use identical ApplicationSet structure:

```yaml
spec:
  generators:
    - git:
        repoURL: ${REPO_URL}
        revision: ${TARGET_REVISION}
        directories:
          - path: K8s/<stack>/*
  template:
    metadata:
      name: '<stack>-{{path.basename}}'
    spec:
      project: <stack>
      source:
        path: '{{path}}'
        kustomize: {}
      destination:
        namespace: <stack>
```

**Naming Convention**: `<stack>-<directory>` (e.g., `observability-loki`, `backstage-dex`)

## Directory Structure Convention

Every stack follows this pattern:

```
K8s/<stack>/
├── applicationset-<stack>.yaml    # App-of-Apps generator
├── infrastructure/                # Namespace, RBAC, SecretStores
├── governance/                    # ResourceQuota, LimitRange
└── <component>/                   # Individual components (Helm via Kustomize)
```

**Order**: infrastructure → governance → components (alphabetical within same wave)

## Kustomize as Universal Abstraction

All components use Kustomize, even for Helm charts:

```yaml
helmCharts:
  - name: <chart-name>
    repo: <helm-repo-url>
    version: <version>
    releaseName: <release>
    namespace: <namespace>
    valuesFile: values.yaml
```

**Benefits**: Helm charts versioned in Git, values files visible, common label injection

## Common Labels (Kustomize Injection)

All resources receive these labels via Kustomize:

```yaml
app.kubernetes.io/part-of: idp
app.kubernetes.io/name: <component>
app.kubernetes.io/instance: <release>
app.kubernetes.io/version: <version>
app.kubernetes.io/component: <tier>
owner: platform-team
business-unit: infrastructure
environment: demo
```

## Secrets Management Pattern

**Flow**: Vault → ExternalSecret (GitOps) → Kubernetes Secret (auto-generated) → Workload

**SecretStore**: One per namespace (not ClusterSecretStore)

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: <namespace>
  namespace: <namespace>
spec:
  provider:
    vault:
      server: "http://vault.vault:8200"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "<namespace>"
          serviceAccountRef:
            name: <namespace>-eso
```

**ExternalSecret**: Defines mapping from Vault to K8s Secret

**Security**: Vault auth via Kubernetes ServiceAccount (no tokens in manifests)

## Sync Policy (Universal Configuration)

All applications use identical sync policy:

```yaml
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
```

**Exception**: `platform-policies` has `limit: 5`, `maxDuration: 5m`, and adds `SkipDryRunOnMissingResource=true`

## ignoreDifferences (Standard Patterns)

All ApplicationSets include these ignoreDifferences:

```yaml
ignoreDifferences:
  - group: admissionregistration.k8s.io
    kind: MutatingWebhookConfiguration
    jqPathExpressions:
      - '.webhooks[]?.clientConfig.caBundle'
  - group: admissionregistration.k8s.io
    kind: ValidatingWebhookConfiguration
    jqPathExpressions:
      - '.webhooks[]?.clientConfig.caBundle'
  - group: ""
    kind: Secret
    jsonPointers: [/data, /metadata/labels]
  - group: ""
    kind: ServiceAccount
    jsonPointers: [/secrets]
  - group: external-secrets.io
    kind: ExternalSecret
    jsonPointers: [/status, /metadata/generation]
```

**Rationale**: Ignore fields managed by controllers (cert-manager, ESO, K8s itself)

## ArgoCD Projects

One AppProject per stack:

- `backstage` → namespace: backstage
- `cicd` → namespace: cicd
- `events` → namespace: argo-events
- `observability` → namespaces: observability, kube-system
- `platform` → namespace: kyverno-system
- `security` → namespace: security
- `default` → wildcard (not used by app stacks)

**Configuration**: Projects define allowed sourceRepos (single repo) and destinations (specific namespaces)

## ArgoCD Configuration

**Location**: `IT/argocd/` (Kustomize)
- ArgoCD Helm chart values
- AppProject definitions (6 projects)
- Service patches for Gateway API compatibility
- Common labels/annotations via Kustomize

**Resource Tracking**: annotation-based (not label-based)

**Resource Exclusions**: Configured in `argocd-cm` to exclude Endpoints, EndpointSlice, Leases, Cilium internals, Kyverno reports

## Policy as Code

**Engine**: Kyverno + Policy Reporter

**Policies** (4 ClusterPolicies):
- `enforce-namespace-labels`: validationFailureAction=enforce
- `require-component-labels`: validationFailureAction=audit
- `audit-business-labels`: validationFailureAction=audit
- `audit-namespace-resource-governance`: validationFailureAction=audit

**Policy Location**: `Policies/rules/`

**Policy Sync**: Via `platform-policies` Application with sync-wave "1"

## Repository Structure

**Git Repo**: https://github.com/rou-cru/idp-blueprint.git
**Branch**: main
**Polling**: ArgoCD default (3 minutes)

**Deployment Flow**:
1. Developer commits to Git
2. ArgoCD detects change (polling)
3. Auto-sync triggered
4. Kustomize build → Helm template → kubectl apply --server-side
5. SelfHeal active (reverts manual changes)
6. Kyverno validates

## Disaster Recovery

**Full cluster recreation**:
```bash
task destroy  # Remove cluster
task deploy   # Recreate everything
```

**Result**: All 20 applications sync automatically from Git after ArgoCD bootstrap. Vault secrets require manual re-seeding via `Scripts/vault-seed.sh`.

## Application Count

- **ApplicationSets**: 5 (observability, backstage, cicd, security, events)
- **Applications**: 20 total (19 auto-generated + 1 manual platform-policies)
- **Distribution**:
  - observability: 7 apps
  - backstage: 4 apps
  - cicd: 4 apps
  - security: 2 apps
  - events: 2 apps
  - platform: 1 app

## Helm Repositories

15+ Helm repositories configured as ArgoCD repos:
- prometheus-community, grafana, kyverno, argo-project
- external-secrets, jetstack, bitnami, cilium
- hashicorp, fluent, aqua, policy-reporter
- open-telemetry, pixie-operator, sonarsource

**Authentication**: None (all public repos)

## Demo vs Production Characteristics

This project serves dual purposes:
1. **Demo Environment**: Deployable on laptop-class hardware for education/demonstration
2. **Reference Architecture**: Production-ready patterns for real IDP implementations

### Intentional Demo Simplifications (NOT Security Issues)

**Credentials**: Simple admin/argo login
- **Rationale**: Fast demo setup without external dependencies
- **Production Pattern**: SSO/OIDC integration with Dex (architecture included)

**TLS Configuration**: `server.insecure: "true"` in ArgoCD
- **Rationale**: Simplifies local setup, Gateway handles TLS termination
- **Production Pattern**: End-to-end TLS with proper certificates

**RBAC**: Empty `argocd-rbac-cm`
- **Rationale**: Single admin user sufficient for demo
- **Production Pattern**: Role-based access via SSO groups

**DNS**: nip.io for local access (192-168-65-16.nip.io)
- **Rationale**: No real DNS or public endpoint needed for local demo
- **Production Pattern**: Real DNS with ingress controller or LoadBalancer

**Webhooks**: Emulated, not genuinely internet-exposed
- **Rationale**: Demo deployable on isolated networks (home lab)
- **Production Pattern**: Public endpoints with webhook authentication

**Secrets Bootstrap**: config.toml with plaintext initial values
- **Rationale**: Quick start for demo user
- **Production Pattern**: External secret injection via CI/CD or sealed secrets

### Production-Ready Patterns (Already Implemented)

- GitOps three-layer architecture
- ApplicationSet App-of-Apps pattern
- External Secrets Operator with Vault backend
- Kustomize universal abstraction
- Server-side apply for better conflict resolution
- Policy as Code with Kyverno
- Observability stack (Prometheus, Grafana, Loki)
- Resource quotas and governance
- Common label taxonomy
- Sync waves for ordering
- Proper ignoreDifferences configuration

**Design Principle**: Demo simplifications are localized to bootstrap/config. Application stacks follow production patterns.

## Task Orchestration

**Bootstrap sequence** (`Taskfile.yaml`):
1. `k3d:create` → Create k3s cluster
2. `bootstrap:it:apply-namespaces` → Create base namespaces
3. `bootstrap:it:bootstrap` → Apply CRDs, ServiceAccounts, PriorityClasses
4. `bootstrap:cilium:deploy` → Install CNI
5. `bootstrap:it:deploy-secret-and-certs` → Deploy Vault + Cert-Manager
6. `bootstrap:external-secrets:deploy` → Deploy ESO
7. `bootstrap:argocd:deploy` → Deploy GitOps engine
8. `bootstrap:gateway:deploy` → Deploy Gateway API
9. `stacks:policies` → Apply via ArgoCD
10. `stacks:deploy` → Apply all ApplicationSets

**Stack deployment** (`Task/stacks.yaml`): Each stack has `envsubst < applicationset-<stack>.yaml | kubectl apply --server-side`

**Feature Gates**: FUSE_* variables control which stacks deploy
