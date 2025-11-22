---
title: Backup & Restore
sidebar:
  label: Backup & Restore
  order: 2
---
---


Not everything deserves a backup. Treat Git as the truth for configuration and focus backups on mutable state you can’t deterministically recreate.

## Map the sources of truth

Conceptual map (sin diagrama):

- **Config (Git)**: manifiestos, values, policies, SLOs → reconciliados por ArgoCD.
- **Estado**: Vault (secrets/policies), Grafana (si no está en Git), Prometheus TSDB (opcional).
- **Efímero**: Loki (replayable), estado runtime de ArgoCD (se reconstruye).

![Backup scope](../assets/images/operate/backup-scope.jpg){ loading=lazy }

## Minimum viable backups from demo to prod

- Vault: export policies and KV data regularly; protect unseal material.
- Grafana: prefer dashboards as code; if not, snapshot provisioning folders/DB.
- Certificates: keep CA materials; cert-manager can re‑issue leaf certs.
- Git: mirror repository; backups of CI pipelines as needed.

Nice‑to‑have / optional:

- Prometheus TSDB: only if you need long history; otherwise rely on short retention and external sinks.
- Loki: treat as forensic; back up only if compliance requires.

## Restore choreography — high level

Flujo de restauración resumido:

1) Rebuild del clúster + bootstrap (IT/).  
2) Restaurar Vault (unseal + importar backup).  
3) Reconectar ArgoCD a Git (AppProjects + ApplicationSets).  
4) Dejar que los stacks sincronicen y validar UIs/alertas.  

Checklist:

- Recreate cluster and apply bootstrap (IT/).
- Restore Vault (policies + data); rebind ESO roles.
- Reapply ArgoCD projects and ApplicationSets; let stacks converge.
- Verify UIs and secrets consumption; re‑issue certs if needed.

:::tip
This creates a `.zip` file in your working directory containing the JSON export.
:::
