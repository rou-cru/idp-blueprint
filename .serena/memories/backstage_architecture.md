# Backstage Architecture & Integration (validated 2025-12-27)

## Deployment Model
- **ApplicationSet**: `K8s/backstage/applicationset-backstage.yaml` uses a Git generator over `K8s/backstage/*`.
- **Dynamic vars**: ApplicationSet patches ConfigMaps `idp-vars-backstage` and `idp-vars-dex` with `DNS_SUFFIX`, `CLUSTER_NAME`, `GITHUB_ORG`, `GITHUB_REPO`, `GITHUB_BRANCH`, `GITHUB_TOKEN`.
- **Target namespace**: `backstage`.

## Backstage Helm Configuration (`K8s/backstage/backstage/values.yaml`)
- **Image**: `docker.io/roucru/idp-blueprint-dev-portal:latest`.
- **PostgreSQL**: Enabled (Bitnami), PVC size `8Gi`.
- **Init container**: `wait-for-dex` (image `roucru/idp-blueprint:ops`) blocks until Dex OIDC endpoint is ready.
- **ServiceAccount**: `backstage-kubernetes`.

## Configuration Rendering
- **Template**: `K8s/backstage/backstage/templates/cm-tpl.yaml` (`app-config.override.yaml`).
- **Renderer Job**: `K8s/backstage/backstage/job-renderer.yaml` (`backstage-config-renderer`).
  - Reads vars from ConfigMap `idp-vars-backstage` (mounted at `/vars`).
  - Optional dev fallback: sources `/vars/env` if present.
  - Uses `envsubst` to render and writes ConfigMap `backstage-app-config-override`.
- **Runtime mount**: Backstage mounts `backstage-app-config-override` via `extraAppConfig`.

## Integrations (from `cm-tpl.yaml`)
- **OIDC**: Dex metadata URL `https://dex.${DNS_SUFFIX}/.well-known/openid-configuration`.
- **Catalog**: GitHub provider reading `Catalog/**/*.yaml` from `${GITHUB_ORG}/${GITHUB_REPO}` `${GITHUB_BRANCH}`.
- **Policy Reporter**: Proxy and API target `http://policy-reporter.kyverno-system.svc.cluster.local:8080`.
- **Grafana**: Domain `https://grafana.${DNS_SUFFIX}` with proxy path `/grafana/api`.
- **ArgoCD**: Backend plugin pointing to `http://argocd-server.argocd.svc.cluster.local`.

## Secrets
- **Backstage app**: `K8s/backstage/backstage/backstage-app-externalsecret.yaml`.
- **PostgreSQL**: `K8s/backstage/backstage/backstage-postgres-externalsecret.yaml`.
- **Dex**: `K8s/backstage/dex/dex-externalsecret.yaml`.
