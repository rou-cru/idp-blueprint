# Secrets Management Architecture (validated 2025-12-04)

## Resumen
- Patrón: Vault + External Secrets Operator (ESO) como fuente única; `config.toml` provee semillas pero valores finales viven en Vault.
- Estado demo actual expone valores en claro en `config.toml` (incluye `github_token`, credenciales de registry y passwords por defecto). Estos se cargan a Vault mediante tareas; deben vaciarse/rotarse antes de uso real.
- Vault corre en modo standalone, sin TLS (`tls_disable="true"`) y con key-shares=1/threshold=1 (`IT/vault/values.yaml`).
- Secrets engines habilitados en init: kv-v2, database, transit (`Scripts/vault-init.sh` 132-140).
- Política `eso-policy` permite acceso amplio a `secret/*`; roles creados: eso-argocd-role, eso-cicd-role, eso-observability-role, eso-backstage-role (archivo `Scripts/vault-init.sh` 145-195).

## Flujo de inicialización
- `task deploy` → Helm despliega Vault (`Task/bootstrap.yaml` 225-232). Luego `task vault:init` inicializa, guarda unseal key y root token en Secret `vault-init-keys` (K8s, namespace `vault-system`). En prod se debe evitar almacenar root token en cluster.
- `vault-generate-secrets` matriz (Task/bootstrap.yaml 150-218) escribe en Vault paths:
  - ArgoCD: `secret/argocd/admin` keys `admin.password` (bcrypt), `username`, `plainPassword`.
  - Grafana: `secret/grafana/admin` `admin-password`.
  - SonarQube: `secret/sonarqube/admin` `password`; `secret/sonarqube/monitoring` `passcode`.
  - Docker registry: registry/username/password (usa valores de config.toml hoy no vacíos).
  - Backstage: `backendSecret` (random), `dexClientSecret` (de config), `githubToken` (de config), `postgres adminPassword/appPassword` (random si vacío).
- Generación usa `Scripts/vault-generate.sh`: si var vacío → random 32B base64; soporta `enc` base64/hex y hash bcrypt para ArgoCD.

## ESO y SecretStores
- ESO chart configurado en `IT/external-secrets/values.yaml` con ServiceMonitor y webhook TLS via cert-manager.
- Per-namespace ServiceAccount `external-secrets` (ej. `IT/serviceaccounts/eso-argocd.yaml`, `K8s/cicd/infrastructure/eso-cicd.yaml`).
- SecretStores apuntan a `http://vault.vault-system.svc.cluster.local:8200` (HTTP demo). Ejemplos: `IT/external-secrets/argocd-secretstore.yaml` (role `eso-argocd-role`), `K8s/cicd/infrastructure/cicd-secretstore.yaml` (role `eso-cicd-role`). Sync-wave -1 aplicado en SecretStores.
- ExternalSecrets: merge en `argocd-secret` con `creationPolicy: Merge` y `deletionPolicy: Retain` (`IT/external-secrets/argocd-admin-externalsecret.yaml`); owner pattern en Grafana, Backstage, etc. (ver stack folders).

## Demo vs producción
- Demo: TLS desactivado, root token/unseal en K8s, políticas amplias, passwords conocidas cargadas desde `config.toml`. Esto facilita `task deploy` pero no es seguro.
- Producción recomendado: habilitar TLS en Vault y SecretStore URLs, usar HA Raft, auto-unseal (KMS), vaciar passwords en `config.toml` para generación aleatoria, políticas por namespace, eliminar PAT/registry creds del repo, NetworkPolicies para Vault.

## Alertas/acciones inmediatas
- `config.toml` contiene credenciales reales/ejemplo (`github_token`, docker registry). Rotar y poner en blanco antes de compartir.
- Backstage depende de secrets `dexClientSecret` y `githubToken`; si se dejan vacíos, `vault-generate.sh` usará random para token GitHub? No: var vacía => random, lo que puede romper integraciones; set via config o Admin cargue manualmente.

## Diagnóstico rápido
- Ver estado ESO/Vault: `kubectl get externalsecret -A`, `kubectl get secretstore -A`, `kubectl exec -n vault-system vault-0 -- vault status`.
- Comprobar seeding: `kubectl exec -n vault-system vault-0 -- env VAULT_TOKEN=$(kubectl get secret vault-init-keys -n vault-system -o jsonpath='{.data.root-token}' | base64 -d) vault kv get secret/argocd/admin`.
- Forzar resync: `kubectl annotate externalsecret <name> -n <ns> force-sync="$(date +%s)"`.
