# Automation & Events Architecture (validated 2025-12-27)

## Overview
- **Event Bus**: Argo Events (NATS JetStream).
- **Workflow Engine**: Argo Workflows (executes the logic).
- **Pattern**: Event-Driven Architecture where `EventSources` listen for external signals and `Sensors` trigger `Workflows` to perform infrastructure actions (GitOps automation, remediation, provisioning).
- **Status**: Argo Events is always deployed. Argo Workflows (`cicd` stack) is feature-gated (`FUSE_CICD`) and disabled by default in the demo config.

## 1. Event Sources (Ingestion)
Located in `K8s/events/argo-events/`, running in `argo-events` namespace.

| Name | Type | Port | Endpoint | Description |
| :--- | :--- | :--- | :--- | :--- |
| `backstage` | Webhook | 12001 | `/backstage/provision` | Receives provisioning requests from Backstage Scaffolder. |
| `alertmanager` | Webhook | 12000 | `/webhook` | Receives firing alerts from Prometheus Alertmanager. |
| `argocd-notifications` | Webhook | 12002 | `/argocd/notifications` | Receives sync/health status events from ArgoCD. |

## 2. Sensors (Filtering & Triggering)
Sensors filter incoming events and map data to Workflow parameters.

### `app-provisioning-sensor`
- **Source**: `backstage` (Event: `provision`).
- **Filter**: `eventType == "provision-app"`.
- **Action**: Triggers `provision-app-workflow` in `cicd` namespace.
- **Parameters**: Maps `appName`, `repoUrl`, `dockerImage`, `owner`, `environment`, etc. from the webhook payload to the workflow.

### `slo-remediation-sensor`
- **Source**: `alertmanager` (Event: `slo-alerts`).
- **Trigger 1**: `slo == "argocd-application-health"`.
  - **Action**: Triggers `remediate-argocd-unhealthy`.
  - **Target**: The specific application and namespace identified in the alert labels.
- **Trigger 2**: `slo == "externalsecrets-sync-success"`.
  - **Action**: Triggers `remediate-externalsecret-failure`.

### `argocd-notifications-sensor`
- **Source**: `argocd-notifications` (Event: `notifications`).
- **Trigger 1**: `eventType == "argocd.app.sync.failed"`.
- **Trigger 2**: `eventType == "argocd.app.health.degraded"`.
- **Action**: Triggers `remediate-argocd-unhealthy` (force sync logic) to attempt self-healing.

## 3. Workflows (Execution)
Templates defined in `K8s/cicd/argo-workflows/workflow-templates/`.

### `provision-app-workflow`
A comprehensive "Day 1" onboarding pipeline:
1.  **Create Namespace**: Generates Namespace, ResourceQuota, and LimitRange imperatively (kubectl).
2.  **Build Image**: Uses **Kaniko** to build and push the container image from the provided git repo.
3.  **Create GitOps App**: Generates the ArgoCD `Application` resource pointing to the `k8s/` directory of the repo.
4.  **Wait**: Polls until the Deployment is `Available`.

### `remediate-argocd-unhealthy`
A "Day 2" operational pipeline:
1.  **Force Sync**: Executes `argocd app sync --force --prune` using the ArgoCD CLI against the in-cluster server.
2.  **Context**: Uses `argo-workflow-argocd-token` secret for authentication.

## 4. Operational Gaps (Demo Mode)
- **FUSE_CICD=false**: By default, the `cicd` stack is not deployed. Sensors will receive events (e.g., from Alertmanager) and attempt to create Workflows, but these will fail or hang if the Workflow CRD/Controller is missing or if the `cicd` namespace is not provisioned with the necessary ServiceAccounts.
- **Webhooks**: Integration requires configuring the upstream senders (Backstage, Alertmanager, ArgoCD) to point to the `*-eventsource-svc` Services.
  - *Confirmed*: Alertmanager is configured correctly in `K8s/observability`.
  - *Confirmed*: Backstage app-config needs to point to the event source for scaffolding actions.
