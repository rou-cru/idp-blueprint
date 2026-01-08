# Automation & Events Architecture (validated 2025-12-27)

## Overview
- **Eventing**: Argo Events in `K8s/events/argo-events`
- **Workflow Engine**: Argo Workflows templates in `K8s/cicd/argo-workflows/workflow-templates`
- **Feature Gate**: `config.toml` sets `fuses.cicd=false` by default

## Event Sources (Webhook Ingress)
Located in `K8s/events/argo-events/` and deployed in `argo-events` namespace.

| Name | Event Name | Port | Endpoint | Service |
| :--- | :--- | :--- | :--- | :--- |
| `backstage` | `provision` | 12001 | `/backstage/provision` | `backstage-eventsource-svc` |
| `alertmanager` | `slo-alerts` | 12000 | `/webhook` | `alertmanager-eventsource-svc` |
| `argocd-notifications` | `notifications` | 12002 | `/argocd/notifications` | `argocd-notifications-eventsource-svc` |

## Sensors (Filters and Triggers)
All sensors submit Workflows into the `cicd` namespace via `workflowTemplateRef`.

### `app-provisioning` (`K8s/events/argo-events/app-provisioning-sensor.yaml`)
- **Source**: EventSource `backstage`, event `provision`
- **Filter**: `body.eventType == "provision-app"`
- **Workflow**: `provision-app-workflow` with `generateName: provision-app-`
- **Parameter Mapping**: `appName`, `repoUrl`, `owner`, `businessUnit`, `environment`, `containerPort`, `replicas`, `dockerRegistry`, `dockerImageName`, `dockerImageTag`

### `slo-remediation` (`K8s/events/argo-events/slo-remediation-sensor.yaml`)
- **Source**: EventSource `alertmanager`, event `slo-alerts`
- **Trigger A**: `slo == "argocd-application-health"` → `remediate-argocd-unhealthy`
  - Parameters: `body.alerts.0.labels.name` → `app-name`, `body.alerts.0.labels.dest_namespace` → `namespace`
- **Trigger B**: `slo == "externalsecrets-sync-success"` → `remediate-externalsecret-failure`
  - Parameters: `body.alerts.0.labels.name` → `externalsecret-name`, `body.alerts.0.labels.namespace` → `namespace`

### `argocd-notifications` (`K8s/events/argo-events/argocd-notifications-sensor.yaml`)
- **Sources**: EventSource `argocd-notifications`, event `notifications`
- **Filters**: `body.eventType == "argocd.app.sync.failed"` and `body.eventType == "argocd.app.health.degraded"`
- **Workflow**: `remediate-argocd-unhealthy` with distinct `generateName` prefixes
- **Parameter Mapping**: `body.app` → `app-name`, `body.namespace` → `namespace`

## EventBus (Transport)
`K8s/events/argo-events/eventbus.yaml` defines a JetStream EventBus:
- **JetStream version**: 2.10.10
- **Replicas**: 3
- **Persistence**: `ReadWriteOnce` volume, `1Gi`
- **Anti-affinity**: prefer spreading across nodes by `kubernetes.io/hostname`
- **Resources**: requests `20m/64Mi`, limits `100m/128Mi`

## Workflow Templates (Execution)

### `provision-app-workflow`
- **Steps**: create Namespace + ResourceQuota + LimitRange (kubectl), build/push image (Kaniko), create ArgoCD Application, wait for Deployment availability
- **ServiceAccount**: `argo-workflow`

### `remediate-argocd-unhealthy`
- **Action**: `argocd app sync --force --prune` against `argocd-server.argocd.svc.cluster.local:443`
- **Token**: `argo-workflow-argocd-token` secret key `token`
- **ServiceAccount**: `argo-workflow`
