# SRE/SLI/SLO — Pendientes / problemas a resolver (2025-12-19)

## Pendientes inmediatos
- Aplicar en cluster el nuevo SLO de latencia ArgoCD (`argocd-reconcile-latency-p95`) y su inclusion en `K8s/observability/slo/kustomization.yaml`.
- Verificar que los dashboards de Pyrra se provisionen en Grafana: confirmar label/sidecar (`grafana_dashboard` por defecto). Ajustar `dashboards.label/labelValue` si Grafana usa otro selector.

## Limitaciones tecnicas actuales
- **Vault latency**: solo expone summary (`vault_core_handle_request{quantile=...}`), no histograms. Pyrra no soporta latencia con summaries → no SLO de latencia valido sin instrumentacion/proxy.
- **Argo Workflows**: falta metrica real de success rate por workflow (no existe `argo_workflows_count`). SLO actual es proxy (controller stability / k8s request).

## Cobertura SLO faltante (si se decide ampliar)
- Kubernetes API Server (availability + latency).
- Cert‑Manager (cert ready 100%).
- Grafana UI availability.
- Backstage UI availability y Scaffolder success (requiere instrumentacion).
- SonarQube availability.
- Synthetic monitoring (blackbox) y/o log‑based SLIs (Loki recording rules).

## Observaciones de calidad SLO
- Evitar usar solo latencia como sustituto de availability (errores rapidos quedan “verdes”).
- Mantener 1 SLO availability + 1 SLO latency solo para servicios user‑visible con histograma confiable.
