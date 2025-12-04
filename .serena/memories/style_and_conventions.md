# Style and Conventions (validated 2025-12-04)

- **Label estándar**: ver `Docs/src/content/docs/reference/labels-standard.md`; namespaces deben llevar `app.kubernetes.io/part-of`, `owner`, `business-unit`, `environment` con valores demo por defecto (`idp`, `platform-team`, `infrastructure`, `demo`).
- **Prioridades**: PriorityClasses definidas en `IT/priorityclasses/priorityclasses.yaml` (platform-* para control planes/dashboards/cicd/etc., user-workloads, cicd-execution, unclassified-workload). Usarlas coherentemente con el servicio.
- **Documentar Helm values**: comentarios `# --` y `## @section` compatibles con helm-docs (ejemplo en labels-standard.md). Usa `task docs` (`Task/utils.yaml`) para regenerar metadata y helm-docs; `task docs:astro:*` para sitio Astro/Starlight en `Docs/`.
- **Tooling**: trabajar en Devbox o Dev Container; `devbox.json` incluye kubectl, helm, kustomize, k3d, cilium CLI, argocd CLI, yamllint, shellcheck, hadolint, markdownlint, checkov, trufflehog, helm-docs, etc. pnpm/node para Docs.
- **Estructura repo**: `IT/` bootstrap infra (Cilium, cert-manager, Vault, ESO, ArgoCD, Gateway), `K8s/` stacks GitOps (ApplicationSets), `Policies/` Kyverno+Policy Reporter, `Docs/` sitio.
- **TLS/formatos**: Recursos deben especificar unidades explícitas (m, Mi/Gi) y labels consistentes; cilium-agent puede no tener limits según chart defaults (no enforced aquí).
