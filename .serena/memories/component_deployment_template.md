# Component Deployment Template (validated 2025-12-04)

## config.toml claves útiles
- `[versions]`, `[network]`, `[git]`, `[passwords]`, `[fuses]`, `[registry]`, `[operational]`, `[argocd]` se consumen vía `Scripts/config-get.sh` y `Taskfile.yaml`. Fuses controlan tareas en `Task/stacks.yaml`; prod habilita HA ArgoCD solo si `fuses.prod=true`.

## Patrón AppSet real
- ApplicationSets viven en `K8s/<stack>/applicationset-<stack>.yaml`; usan git generator `K8s/<stack>/*`, nombre `<stack>-{{path.basename}}`, project=<stack>, namespace del stack, syncPolicy con ServerSideApply/PruneLast/ApplyOutOfSyncOnly/RespectIgnoreDifferences y retry 10. IgnoreDifferences incluye Secrets, SA secrets, ExternalSecret status, StatefulSet status (observability añade SLO status). Variables `${REPO_URL}`/`${TARGET_REVISION}` se sustituyen con `envsubst` en `Task/stacks.yaml`.

## Estructura esperada de un stack
- `applicationset-<stack>.yaml`
- `governance/` (namespace + quota + limitrange, con sync-wave -2 en namespace)
- `infrastructure/` (SecretStore/ESO si aplica)
- uno o más componentes (Helm vía kustomize helmCharts o manifests), cada uno con `kustomization.yaml`, `values.yaml`/`Chart.yaml` o manifests y README recomendado.

## Labels y recursos
- Labels estándar en `Docs/src/content/docs/reference/labels-standard.md`; aplicarlos a namespaces y recursos. No existe inyección global automática, algunos kustomizations usan `includeSelectors: true`.
- Requests/limits obligatorios en workloads; unidades CPU m, memoria Mi/Gi. Cilium agent puede carecer de limits por defaults del chart.

## Sync waves
- Namespace -2, infra/secrets -1, apps 0 por convención; ajustar annotations `argocd.argoproj.io/sync-wave`.

## Task/stacks integración
- Para cada stack hay task en `Task/stacks.yaml` que aplica el ApplicationSet con `envsubst`; fuses controlan el skip (`status` test var). Añadir nuevo stack requiere task similar y fuse en config/vars si se desea gatearlo.

## SecretStores/ESO
- Pattern por namespace: SecretStore apunta a Vault `http://vault.vault-system.svc.cluster.local:8200` v2 + role `eso-<ns>-role`; ExternalSecret usa Owner salvo casos como ArgoCD que usa Merge/Retain.

## Checklist rápido
- `task quality:lint` y `task quality:validate` tras crear componentes.
- Regenerar docs Helm/metadata si se tocan values (`task docs`, `task docs:helm`, `task docs:metadata`).
- Validar render: `kustomize build K8s/<stack>/<componente>` o `helm template` según corresponda.
- Confirmar fuses/config con `task utils:config:print`.

## Notas demo vs prod
- config.toml tiene credenciales demo; vaciar/rotar para entornos reales.
- DNS nip.io + NodePorts 30080/30443; cambiar en `[network]` si hay conflicto.
