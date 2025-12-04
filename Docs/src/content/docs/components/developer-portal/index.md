---
title: Developer Portal
---

Backstage centralizes the developer experience (catalog, docs, service orchestration) and
ships as part of the blueprint via GitOps and ApplicationSets.

- Namespace and guardrails: `K8s/backstage/governance/*`
- Secrets backend: External Secrets + Vault (`K8s/backstage/infrastructure/*`)
- Deployment: official Backstage Helm chart (`K8s/backstage/backstage/*`) with its own
  Postgres + PVC
- Exposure: `HTTPRoute` in `IT/gateway/httproutes/backstage-httproute.yaml` on the
  `idp-gateway`
