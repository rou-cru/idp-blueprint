# Taskfile Env & Design Choices (validated 2025-12-04)

## Variables y entorno
- **Fuente única**: `config.toml` → `Scripts/generate-env.sh` → `.env`. Ejecutado por `internal:generate-env` (run: once). Export global con `set -a && . ./.env && set +a` en `task deploy` para que todos los comandos vean los mismos valores.
- **envsubst**: Plantillas en Git con placeholders (${DNS_SUFFIX}, NodePorts, repo/branch). Sustitución client-side en k3d config, AppProjects, ApplicationSets, Gateway, Backstage, etc. Mantiene portabilidad sin commitear valores locales.
- **Fuses**: `FUSE_*` en .env (default true, prod=false). `Task/stacks.yaml` usa `status` tests para saltar stacks. Permite desactivar políticas/obs/cicd/security/backstage rápido sin tocar manifests.
- **Run-once helpers**: `generate-env`, `validate-tools` evitan trabajo repetido. `validate-tools` verifica kubectl/helm/kustomize/envsubst/jq/dasel/k3d/docker.
- **config-get wrapper**: `Scripts/config-get.sh` limpia comillas de `dasel` evitando bugs en envsubst/helm.
- **Trade-offs**: +determinismo y paridad CI/local; +toggles simples; –manifests no son GitOps puros (requieren envsubst); –hay que regenerar .env tras cambios en config.
- **Override recomendado**: editar `config.toml` y re‑ejecutar `task internal:generate-env` o `task deploy`; evitar exports ad-hoc.

## Flujo de despliegue (Taskfile.yaml)
- `task deploy`: genera .env, exporta vars, llama `deploy-core`.
- `deploy-core` pasos: k3d:create → apply-namespaces/priorities/CRDs → Cilium → cert-manager+Vault → ESO → ArgoCD → Gateway → policies (Kyverno) → stacks (AppSets) respetando fuses.
- `destroy` elimina cluster k3d; `redeploy` hace destroy+deploy.

## Taskfiles incluidos
- `Task/k3d.yaml`: crea/destroy cluster; renderiza `IT/k3d-cluster.yaml` con envsubst de NodePorts.
- `Task/bootstrap.yaml`: instala CRDs, Cilium, cert-manager, Vault (init+secrets), ESO, ArgoCD (url con DNS_SUFFIX; HA si FUSE_PROD), Gateway (kustomize+envsubst+NodePort patch) y AppProjects (envsubst appproject-*.yaml). Verificación de NodePorts.
- `Task/stacks.yaml`: aplica ApplicationSets por stack con envsubst; guarda por fuse; eventos siempre on.
- `Task/quality.yaml`: lint/validate (yaml/shell/md via yamllint, shellcheck, markdownlint; kubeval/kustomize, hadolint/checkov/trufflehog si configurado).
- `Task/utils.yaml`: config:print, CA export; docs helpers (metadata, helm-docs), docs Astro build/dev.
- `Task/docs.yaml`: wrappers para docs build/dev (Astro) si separados.
- `Task/image.yaml`: build/push multi-arch via docker-bake (no usa envsubst salvo repo/tag).

## Implementación de fuses y waves
- Fuses se evalúan en `status:` de cada task; si `false`, Task salta con mensaje.
- Sync-wave convención: namespaces -2, SecretStore/ESO -1, apps 0; algunos componentes con wave >0 (pyrra wave 2). Gateway patch y verificaciones integradas.

## Por qué este diseño
- Homogeneizar config y evitar drift entre usuarios/CI.
- Permitir datos dinámicos (LAN_IP/DNS_SUFFIX/NodePorts) sin romper GitOps ni tocar manifiestos.
- Reducir requisitos de tooling adhoc: validate-tools fuerza presencia de binarios clave antes de fallar tarde.
- Fuses para operar en hardware reducido y aislar fallas por stack.
- envsubst client-side en vez de ArgoCD plugins/templates: simplicidad y cero dependencias extra.

## Buenas prácticas operativas
- Tras cambiar `config.toml`, re‑genera `.env` (`task internal:generate-env`) o ejecuta `task deploy` directamente.
- Para probar solo un stack: ajusta fuses en `config.toml` o ejecuta `task stacks:<stack>` con .env cargado.
- Usa `task quality:lint` y `task quality:validate` antes de PRs.
- Ajusta `kubectl_timeout`/`sync_timeout` en config.toml para entornos lentos.
