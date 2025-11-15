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

!!! example "A first incident, end-to-end"
    A typical early incident is an SLO burn on the public Gateway (ingress latency or error rate). The flow looks like:

    - Pyrra signals the burn in Grafana (SLO panel turns red).
    - An alert routes to your on-call channel.
    - You open the Troubleshooting Playbook, which links dashboards and runbooks for Gateway, Cilium and workloads behind it.
    - If the issue is config-related, you fix it in Git and let ArgoCD reconcile; if it is capacity-related, you adjust limits/requests or retention and roll forward.

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
