# Vault Issue: Delayed CrashLoop After Hours (Observed 2025-11-29)

## Facts Observed
- Initial bootstrap (`task deploy`/`redeploy`) leaves Vault healthy and operating; External Secrets Operator (ESO) is initially configured to use Vault.
- Several hours after deployment, without code changes or host changes, Vault pod (`vault-0`, namespace `vault-system`) enters `CrashLoopBackOff`.
- Pod details: StartTime ~2025-11-29T02:04Z; over 60 restarts observed by 05:10Z while cluster age ~11h.
- Container state shows repeated liveness probe failures: HTTP 503 from `/v1/sys/health?standbyok=true`; kubelet restarts the container. Last state often `Completed` (exit 0), indicating it is killed by liveness, not by a process crash.
- Vault remains sealed/uninitialized during these restarts (health endpoint returns 503), so it never reaches Ready.
- ESO SecretStores that target Vault report `Ready=False` with `InvalidProviderConfig` / `unable to log in to auth method: context deadline exceeded`; ExternalSecrets show `SecretSyncedError` because Vault is unreachable while sealed.
- No evidence of new deployments or config changes between initial healthy state and the onset of CrashLoop (only `task redeploy`, which is destroy+deploy from same code/host).
- The problem manifests only after some time passes post-deploy, implying a later pod restart (cause not yet determined) triggers the sealed state plus liveness failure loop.