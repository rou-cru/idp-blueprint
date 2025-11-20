---
title: Argo Events — Event Mesh
---

Argo Events is the shared nervous system of the IDP Blueprint. It listens to Kubernetes, Git, and external systems, then fans out triggers to Argo Workflows, ArgoCD, or any HTTP target. The stack is deployed from `K8s/events/*` and synchronized through `task stacks:events`, so every environment boots the same event bus, governance objects, and controller configuration.

## Deployment layout

| Path | Purpose |
|------|---------|
| `K8s/events/governance/` | Namespace, `LimitRange`, and `ResourceQuota` applied in early sync waves so the mesh has reserved capacity.
| `K8s/events/argo-events/values.yaml` | Helm values for the controller + webhook (priority class, tolerations, metrics, resources).
| `K8s/events/argo-events/eventbus.yaml` | Defines the `EventBus` using native NATS with three replicas.
| `K8s/events/applicationset-events.yaml` | ApplicationSet that points ArgoCD to every Eventing folder.

## Scheduling & reliability

- Both controller and webhook use the `platform-events` PriorityClass and pin to control-plane nodes through node affinity and tolerations so automation continues even if worker nodes are under pressure (`values.yaml`).
- Rolling updates use `maxUnavailable: 0` / `maxSurge: 1` to enforce zero-downtime restarts for the controller.
- The EventBus (`eventbus.yaml`) provisions a three-node NATS cluster with token auth; it is the single default bus referenced by all Sensors.

## Building sensors and event sources

1. Create a folder under `K8s/events/<source>-<purpose>/`.
2. Add `EventSource` and `Sensor` manifests that point to the `default` EventBus.
3. Label everything with the canonical metadata (`app.kubernetes.io/part-of: idp`, `owner: platform-team`, etc.) and include governance files if the folder introduces its own namespace.
4. Commit and let the ApplicationSet reconcile it—no manual registration is required.

Common recipes:
- Git webhooks → trigger Argo Workflows templates or invoke the ArgoCD API for intelligent syncs.
- Alertmanager or Prometheus burn-rate alerts → Sensor that dispatches remediation workflows.
- Cron-style schedules → `Calendar` trigger to fan out maintenance jobs.

## Observability & operations

- Metrics: the controller exposes `/metrics` on port `7777`; a `ServiceMonitor` with selector `prometheus: kube-prometheus` is created automatically so Prometheus scrapes it.
- Health: `kubectl -n argo-events get pods` verifies controller/webhook readiness; `kubectl -n argo-events get eventbus` shows NATS replicas.
- Redeploy: `task stacks:events` reapplies the ApplicationSet and Helm release; use it after changing values or adding new sources.
- Cleanup/testing: `task deploy` already includes the Events stack; `task destroy` removes it with the rest of the platform.

## Extending to other stacks

Treat Events as a cross-cutting concern:
- CI/CD: Workflows triggered by Sensor payloads instead of manual submissions.
- Security: Stream Trivy or Kyverno reports into Sensors for auto-ticketing or rollback automation.
- SRE automation: Watch Gateway/Certificate events and run recovery flows.

Design Sensors so they emit structured CloudEvents (or JSON payloads) that downstream tasks can parse consistently.
