# GitOps Architecture (validated 2025-12-04)

## Capas
- **Bootstrap (imperativo)**: `Taskfile.yaml` ejecuta `k3d:create` → namespaces/CRDs/SA/PriorityClasses → Cilium → cert-manager+Vault → ESO → ArgoCD → Gateway (`Task/bootstrap.yaml`). Imperativo para evitar chicken‑egg; ArgoCD no se autoinstala.
- **Policies**: Application `platform-policies` (`Policies/app-kyverno.yaml`) proyecto `platform`, destino `kyverno-system`; syncOptions incluyen `SkipDryRunOnMissingResource=true`, retry 5, backoff 5s; recursos con sync-wave "1" vía `Policies/kustomization.yaml`. Incluye 4 ClusterPolicies.
- **Stacks (AppSets)**: 5 ApplicationSets (`K8s/*/applicationset-*.yaml`): observability, backstage, cicd, security, events. Git generator `K8s/<stack>/*`, template nombre `<stack>-{{path.basename}}`, proyecto=<stack>, namespace del stack, syncPolicy común (prune/selfHeal + ServerSideApply/PruneLast/ApplyOutOfSyncOnly/RespectIgnoreDifferences, retry 10). IgnoreDifferences incluye webhooks CA bundles, Secrets, ServiceAccount secrets, ExternalSecret status; observability añade SLO status.

## Apps por stack (confirmado)
- observability: fluent-bit, governance, infrastructure, kube-prometheus-stack, loki, pyrra, slo (7)
- backstage: infrastructure, governance, dex, backstage (4)
- cicd: infrastructure, governance, argo-workflows, sonarqube (4)
- security: governance, trivy (2)
- events: governance, argo-events (2)
- platform-policies: 1 manual app

## AppProjects
- Definidos en `IT/argocd/`: backstage, cicd, events, observability, platform, security. No existe AppProject "default" en el repo.

## Secretos (GitOps)
- Patrón: Vault → SecretStore (por namespace) → ExternalSecret → Secret. API `external-secrets.io/v1`. ServiceAccount fijo `external-secrets`; roles Vault `eso-<namespace>-role` configurados en `Scripts/vault-init.sh`.
- SecretStore server URL demo: `http://vault.vault-system.svc.cluster.local:8200`, path `secret`, version v2. Ejemplos: `IT/external-secrets/argocd-secretstore.yaml`, `K8s/cicd/infrastructure/cicd-secretstore.yaml`.
- ExternalSecret ArgoCD usa `creationPolicy: Merge` + `deletionPolicy: Retain` para preservar `server.secretkey` (`IT/external-secrets/argocd-admin-externalsecret.yaml`). Otros usan Owner.

## Helm repos configurados en ArgoCD
15 repos en `IT/argocd/values.yaml` (argo, prometheus-community, grafana, open-telemetry, sonarsource, external-secrets, jetstack, kyverno, aqua, policy-reporter, bitnami, fluent, pixie-operator, hashicorp, cilium); todos públicos, sin credenciales.

## Simplificaciones demo
- ArgoCD `server.insecure: true` (TLS termina en Gateway). Passwords y repo URLs se inyectan vía `.env`. nip.io usado para DNS local.
- Resources reciben etiquetas comunes solo donde cada chart/manifest las declara; no hay inyección global obligatoria.

## DR / flujo
- `task destroy` elimina cluster; `task deploy` recrea y sincroniza apps desde Git. Vault requiere re-seeding via `task vault:generate-secrets` tras init.
