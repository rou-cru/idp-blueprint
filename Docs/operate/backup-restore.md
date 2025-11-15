---
# Backup & Restore — Know what to back up vs. what to rebuild

Not everything deserves a backup. Treat Git as the truth for configuration and focus backups on mutable state you can’t deterministically recreate.

## Map the sources of truth

```d2
direction: right

Config: {
  Git: "Manifests, values, policies, SLOs"
}

State: {
  Vault: "Secrets & policies"
  Grafana: "Dashboards/settings (if not Git‑managed)"
  Prometheus: "TSDB (optional; low RPO assumed)"
}

Ephemeral: {
  Loki: "Logs (replayable)"
  ArgoCD: "Runtime state (rebuildable from Git)"
}

Config.Git -> ArgoCD: reconcile
State.Vault -> Workloads: consume via ESO
```

![Backup scope](../assets/images/operate/backup-scope.jpg){ loading=lazy }

## Minimum viable backups (demo → prod)

- Vault: export policies and KV data regularly; protect unseal material.
- Grafana: prefer dashboards as code; if not, snapshot provisioning folders/DB.
- Certificates: keep CA materials; cert-manager can re‑issue leaf certs.
- Git: mirror repository; backups of CI pipelines as needed.

Nice‑to‑have / optional:
- Prometheus TSDB: only if you need long history; otherwise rely on short retention and external sinks.
- Loki: treat as forensic; back up only if compliance requires.

## Restore choreography (high‑level)

```d2
direction: right

Rebuild: "Cluster + bootstrap"
Secrets: "Restore Vault"
GitOps: "ArgoCD reconnects to Git"
Stacks: "Stacks sync (observability, security, CI/CD)"

Rebuild -> Secrets: unseal + import
Rebuild -> GitOps: apply AppProjects + ApplicationSets
GitOps -> Stacks: converge
Stacks -> Users: validate
```

Checklist:
- Recreate cluster and apply bootstrap (IT/).
- Restore Vault (policies + data); rebind ESO roles.
- Reapply ArgoCD projects and ApplicationSets; let stacks converge.
- Verify UIs and secrets consumption; re‑issue certs if needed.

!!! tip
    The fastest “backup” for the platform is the ability to rebuild from Git quickly. Keep bootstrap scripts healthy.
