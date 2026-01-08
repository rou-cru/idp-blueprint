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

## 1.5 EventSource Services (Connectivity)
Each EventSource is exposed via a Kubernetes Service to enable external and internal webhook connectivity.

**Service Configuration:**
- **backstage-eventsource-svc**: Exposes port 12001 for `/backstage/provision`
- **alertmanager-eventsource-svc**: Exposes port 12000 for `/webhook`
- **argocd-notifications-eventsource-svc**: Exposes port 12002 for `/argocd/notifications`

**Access URLs:**
- Alertmanager webhook: `http://alertmanager-eventsource-svc.argo-events.svc.cluster.local:12000/webhook`
- Backstage webhook: `http://backstage-eventsource-svc.argo-events.svc.cluster.local:12001/backstage/provision`
- ArgoCD notifications: `http://argocd-notifications-eventsource-svc.argo-events.svc.cluster.local:12002/argocd/notifications`

**Integration Status:**
- ✅ **Alertmanager**: Fully configured in `K8s/observability/kube-prometheus-stack/values.yaml`
- ⚠️ **Backstage**: Requires manual configuration in Backstage app-config
- ⚠️ **ArgoCD**: Requires notifications webhook configuration in ArgoCD ConfigMap

## 2. Sensors (Filtering & Triggering)
Sensors filter incoming events and map data to Workflow parameters.

### `app-provisioning-sensor`
- **Source**: `backstage` (Event: `provision`).
- **Filter**: `eventType == "provision-app"`.
- **Action**: Triggers `provision-app-workflow` in `cicd` namespace (requires FUSE_CICD=true).
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

## 3. EventBus (Event Transport)
The EventBus provides the underlying message transport for events between EventSources and Sensors.

**Configuration:**
- **Technology**: NATS JetStream
- **Location**: `K8s/events/argo-events/eventbus.yaml`
- **Namespace**: `argo-events`
- **Version**: JetStream 2.10.10
- **Replicas**: 3 (for high availability)
- **Persistence**: 1Gi volume with ReadWriteOnce access mode
- **Anti-Affinity**: PodAntiAffinity configured to distribute replicas across different nodes (topologyKey: kubernetes.io/hostname)
- **Resources**: 
  - Requests: CPU 20m, Memory 64Mi
  - Limits: CPU 100m, Memory 128Mi

**Purpose**: Ensures reliable event delivery with persistence and high availability across the cluster.

## 4. Workflows (Execution)
Templates defined in `K8s/cicd/argo-workflows/workflow-templates/`.

### `provision-app-workflow`
A comprehensive "Day 1" onboarding pipeline:
1.  **Create Namespace**: Generates Namespace, ResourceQuota, and LimitRange imperatively (kubectl).
2.  **Build Image**: Uses **Kaniko** to build and push the container image from the provided git repo.
3.  **Create GitOps App**: Generates the ArgoCD `Application` resource pointing to the `k8s/` directory of the repo.
4.  **Wait**: Polls until the Deployment is `Available`.

**Execution Pattern**: Sensors create Workflow resources with `generateName` (e.g., `provision-app-abc123`) that reference the static `WorkflowTemplate` using `workflowTemplateRef`.

### `remediate-argocd-unhealthy`
A "Day 2" operational pipeline:
1.  **Force Sync**: Executes `argocd app sync --force --prune` using the ArgoCD CLI against the in-cluster server.
2.  **Context**: Uses `argo-workflow-argocd-token` secret for authentication.

## 4.5 Workflow Prerequisites
**Required for workflow execution (depends on FUSE_CICD=true):**

### Namespace `cicd`
- **Purpose**: Target namespace for all workflow executions
- **Deployment**: Created by `K8s/cicd/applicationset-cicd.yaml` when `fuses.cicd=true`
- **Status**: Does NOT exist by default (`fuses.cicd=false` in config.toml)

### ServiceAccount `argo-workflow`
- **Purpose**: Runs workflow pods with necessary permissions
- **Permissions Required**:
  - Create namespaces, resourcequotas, limitranges
  - Read secrets (docker-registry, argocd-token)
  - Interact with ArgoCD API
  - Manage ExternalSecrets (for remediation)

### Secrets
- **argo-workflow-argocd-token**: Authentication token for ArgoCD CLI operations
- **docker-credentials**: Registry credentials for Kaniko builds

## 5. Operational Gaps (Demo Mode)
- **FUSE_CICD=false**: By default, the `cicd` stack is not deployed. Sensors will receive events (e.g., from Alertmanager) and attempt to create Workflows, but these will fail or hang if the Workflow CRD/Controller is missing or if the `cicd` namespace is not provisioned with the necessary ServiceAccounts and secrets.
- **Webhooks**: Integration requires configuring the upstream senders (Backstage, Alertmanager, ArgoCD) to point to the `*-eventsource-svc` Services.
  - ✅ **Alertmanager**: Fully configured in `K8s/observability/kube-prometheus-stack/values.yaml`
  - ⚠️ **Backstage**: Requires manual configuration in Backstage app-config
  - ⚠️ **ArgoCD**: Requires notifications webhook configuration in ArgoCD ConfigMap
