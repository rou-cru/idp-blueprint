# Despliegue IDP Blueprint — Resumen operativo

## Flujo real de `task deploy` (config.toml por defecto)
1. Prechequeos y clúster k3d
   - Verifica inotify.
   - Crea clúster k3d `idp-demo` (1 server + 2 agents) y registry local.
   - Aplica namespaces y PriorityClasses iniciales (IT/namespaces, IT/priorityclasses).
2. CRDs y red
   - Aplica CRDs de Gateway API (v1.2.1) y Prometheus Operator (chart 23.0.0).
   - Instala Cilium 1.18.2 y espera pods Ready.
3. Certificados y secretos
   - Instala cert-manager v1.19.0; aplica CA/ClusterIssuers.
   - Instala Vault 0.31.0, inicializa y unseal; habilita kv-v2, database, transit; configura roles Kubernetes para ESO.
   - Genera secretos iniciales (argocd: argo, grafana: graf, sonarqube: sonar, registry creds rand, backstage secrets rand).
   - Instala External Secrets Operator 0.20.2 y espera Ready.
4. GitOps y gateway
   - Instala ArgoCD chart 8.6.0, aplica AppProjects (platform/obs/cicd/security/events/backstage).
   - Aplica ExternalSecret para credencial admin de ArgoCD.
   - Despliega Gateway API + Cilium Gateway, emite wildcard TLS, verifica NodePorts 30080/30443 y anuncia URLs nip.io (LAN IP → dashed).
5. Stacks vía App + ApplicationSets
   - Aplica la Application de Kyverno/Policy Reporter (platform-policies).
   - Aplica ApplicationSets: observability, cicd, security, backstage, events (events siempre on; resto obedecen fuses en config.toml).
6. Finaliza con “Success 😌”; ArgoCD sigue reconciliando hasta Healthy/Synced.

## Archivos/claves
- `Taskfile.yaml` + `Task/` definen orden; fuses en `config.toml [fuses]` (events no tiene fuse, siempre aplica).
- Versiones de charts leídas desde `config.toml [versions]` vía Scripts/config-get.sh.
- Gateway y nip.io usan NodePorts 30080/30443; DNS_SUFFIX calculado desde LAN IP.
- Secretos iniciales: Vault init + `vault-generate.sh`; ESO sincroniza a K8s.
- Log completo de una ejecución exitosa: `/tmp/task-deploy.log` (25 Nov 2025).

## Detalles útiles
- Tiempo de despliegue observado: ~3 min en laptop (incluye pulls).
- Warnings vistos: finalizer no calificado en app-kyverno; warning de last-applied en service gateway (no bloquea).
- Gateway imprime URLs: argocd/backstage/events/grafana/vault/sonarqube/workflows.

## Documentación ajustada
- Sección “Un solo comando: qué hace realmente `task deploy`” en `Docs/src/content/docs/getting-started/overview.mdx` refleja este flujo con fragmentos de log.
- Credenciales por defecto documentadas: argocd=argo, grafana=graf, sonarqube=sonar (coherentes con config.toml y vault-generate).

## Puntos para futuros LLMs
- Respetar orden bootstrap antes de AppSets; CRDs antes de CRs.
- Kyverno se aplica antes de stacks; events no es opcional.
- Para regenerar docs: `task docs:astro:build` o `task utils:docs:linkcheck`.
- Para limpiar/reintentar: `task destroy` borra clúster y cache; si falta `last-applied` en svc gateway es solo warning.
