# GitOps Architecture (validated 2025-12-27)

## Capas
- **Bootstrap (imperativo)**: `Taskfile.yaml` ejecuta `k3d:create` → namespaces/CRDs/SA/PriorityClasses → Cilium → cert-manager+Vault → ESO → ArgoCD → Gateway (`Task/bootstrap.yaml`). Imperativo para evitar chicken‑egg; ArgoCD no se autoinstala.
- **Policies (AppSet)**: Policies viven bajo `K8s/policies/` y se despliegan vía `applicationset-policies.yaml` (no hay directorio `Policies/` en repo). AppSet usa git generator `K8s/policies/*`, proyecto `policies`, destino `kyverno-system`, syncPolicy con prune/selfHeal + ServerSideApply/PruneLast/ApplyOutOfSyncOnly/RespectIgnoreDifferences y retry 10.
- **Stacks (AppSets)**: ApplicationSets en `K8s/*/applicationset-*.yaml` para observability, backstage, cicd, security, events **y policies**. Git generator `K8s/<stack>/*`, template `<stack>-{{path.basename}}`, project=<stack>, namespace del stack. IgnoreDifferences incluye webhooks CA bundles, Secrets, ServiceAccount secrets, ExternalSecret status (observability añade SLO status).

## Apps por stack (repo)
- observability: fluent-bit, governance, infrastructure, kube-prometheus-stack, loki, pyrra, slo
- backstage: infrastructure, governance, dex, backstage
- cicd: infrastructure, governance, argo-workflows, sonarqube (ojo: `fuses.cicd` está `false` en `config.toml`)
- security: governance, trivy
- events: governance, argo-events
- policies: Git generator `K8s/policies/*`

## AppProjects
- Definidos en `IT/argocd/`: backstage, cicd, events, observability, policies, security.

## Secretos (GitOps)
- Patrón: Vault → SecretStore (por namespace) → ExternalSecret → Secret. API `external-secrets.io/v1`. ServiceAccount fijo `external-secrets`; roles Vault `eso-<namespace>-role` configurados en `Scripts/vault-init.sh`.
- SecretStore demo: `http://vault.vault-system.svc.cluster.local:8200`, path `secret`, version v2. Ejemplos: `IT/external-secrets/argocd-secretstore.yaml`, `K8s/cicd/infrastructure/cicd-secretstore.yaml`.
- ExternalSecret ArgoCD usa `creationPolicy: Merge` + `deletionPolicy: Retain` (`IT/external-secrets/argocd-admin-externalsecret.yaml`). Otros usan Owner.

## Simplificaciones demo
- ArgoCD `server.insecure: true` (TLS termina en Gateway). Passwords y repo URLs se inyectan vía `.env`. nip.io usado para DNS local.
- Labels comunes solo donde cada chart/manifest las declara; no hay inyección global obligatoria.

## DR / flujo
- `task destroy` elimina cluster; `task deploy` recrea y sincroniza apps desde Git. Vault requiere re‑seeding via `task vault:generate-secrets` tras init.
