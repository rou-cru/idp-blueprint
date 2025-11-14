---
# Operate — Run it like a product

Operating this IDP is about tight feedback loops. Treat SLOs as the scoreboard, events as the nervous system, and runbooks as code you can execute and evolve.

## The loop: Detect → Decide → Act → Learn

```d2
direction: right

Detect: {
  Observability: "Prometheus (metrics)\nLoki (logs)\nPyrra (SLOs)"
}

Decide: {
  label: "Routes"
  Alerts: "Alertmanager/Grafana UA"
  Events: "Argo Events (planned)"
}

Act: {
  Workflows: "Argo Workflows"
  GitOps: "ArgoCD sync/refresh"
  HTTP: "Webhooks / APIs"
}

Learn: {
  Dashboards: "Grafana"
  Reports: "Policy Reporter"
}

Detect -> Decide: signals
Decide -> Act: triggers
Act -> Learn: outcomes
Learn -> Detect: new baselines
```

![Alerts pipeline](../assets/images/operate/alerts-pipeline.jpg){ loading=lazy }

## What “good operations” looks like here

- SLOs as code (Pyrra) define expectations; burn rates trigger playbooks.
- GitOps and policies keep intent and reality aligned; drift is fixed automatically.
- Events (planned) connect alerts and changes to reproducible actions.
- Dashboards are the narrative of the last incident; they evolve with runbooks.

## Runbooks you will rely on

- Backup/Restore: know your sources of truth and what to regenerate.
- Upgrades: orchestration order, gates, and rollbacks.
- Scaling & Tuning: knobs that matter (retention, cardinality, priorities).
- Disaster Recovery: rebuild from Git, restore secrets, re‑issue certs.

Use the guides below to operate with confidence:

- [Backup & Restore](../operate/backup-restore.md)
- [Upgrades](../operate/upgrades.md)
- [Scaling & Tuning](../operate/scaling-tuning.md)
- [Disaster Recovery](../operate/disaster-recovery.md)
- [Troubleshooting Playbook](../reference/troubleshooting.md)
