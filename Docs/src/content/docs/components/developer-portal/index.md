---
title: Developer Portal
---

Backstage centraliza la experiencia de desarrollador (catálogo, documentación y orquestación de servicios) y se entrega como parte del blueprint mediante GitOps y ApplicationSets.

- Namespace y guardrails: `K8s/backstage/governance/*`
- Secret backend: External Secrets + Vault (`K8s/backstage/infrastructure/*`)
- Despliegue: Helm chart oficial de Backstage (`K8s/backstage/backstage/*`) con Postgres y PVC propios
- Exposición: `HTTPRoute` en `IT/gateway/httproutes/backstage-httproute.yaml` sobre el `idp-gateway`
