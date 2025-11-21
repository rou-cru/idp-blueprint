# argo-workflows

![Version: 0.45.27](https://img.shields.io/badge/Version-0.45.27-informational?style=flat-square) 

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `0.45.27` |
| **Chart Type** | `` |
| **Upstream Project** | N/A |

## Configuration Values

The following table lists the configurable parameters:

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| artifactRepository.archiveLogs | bool | `false` | Archive logs to the artifact repository. |
| artifactRepository.artifactRepositoryRef | object | `{}` | Reference to a custom artifact repository. |
| artifactRepository.azure | object | `{}` | Azure artifact repository configuration. |
| artifactRepository.customArtifactRepository | object | `{}` | Custom artifact repository configuration. |
| artifactRepository.gcs | object | `{}` | GCS artifact repository configuration. |
| artifactRepository.s3 | object | `{}` | S3 artifact repository configuration. |
| controller.deploymentStrategy | object | `{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0},"type":"RollingUpdate"}` | Rolling update strategy for zero-downtime updates |
| controller.deploymentStrategy.rollingUpdate.maxSurge | int | `1` | Maximum surge pods during update |
| controller.deploymentStrategy.rollingUpdate.maxUnavailable | int | `0` | Maximum unavailable pods during update (0 for zero-downtime) |
| controller.metricsConfig | object | `{"enabled":true}` | Enable Prometheus metrics endpoint. |
| controller.metricsConfig.enabled | bool | `true` | Enable controller metrics endpoint |
| controller.nodeEvents | object | `{"enabled":true}` | Enable node events for workflows. |
| controller.nodeEvents.enabled | bool | `true` | Emit Kubernetes events for nodes |
| controller.parallelism | int | `10` | Parallel workflows allowed |
| controller.priorityClassName | string | `"platform-cicd"` | Priority class for the controller pod. |
| controller.rbac | object | `{"create":true}` | Create RBAC resources for the controller. |
| controller.rbac.create | bool | `true` | Create controller RBAC resources |
| controller.resources | object | `{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}}` | Resource requests and limits for the controller. |
| controller.resources.limits.cpu | string | `"500m"` | CPU limit for the controller |
| controller.resources.limits.memory | string | `"512Mi"` | Memory limit for the controller |
| controller.resources.requests.cpu | string | `"100m"` | CPU request for the controller |
| controller.resources.requests.memory | string | `"256Mi"` | Memory request for the controller |
| controller.retentionPolicy | object | `{"completed":10,"errored":5,"failed":5}` | Retention policy for completed workflows. |
| controller.retentionPolicy.completed | int | `10` | Number of successful workflows to retain |
| controller.retentionPolicy.errored | int | `5` | Number of errored workflows to retain |
| controller.retentionPolicy.failed | int | `5` | Number of failed workflows to retain |
| controller.serviceAccount | object | `{"create":true,"name":"argo-workflow-controller"}` | Service account for the controller. |
| controller.serviceAccount.create | bool | `true` | Create controller service account |
| controller.serviceAccount.name | string | `"argo-workflow-controller"` | Service account name for the controller |
| controller.serviceMonitor | object | `{"additionalLabels":{"prometheus":"kube-prometheus"},"enabled":true}` | Create a ServiceMonitor for Prometheus. |
| controller.serviceMonitor.additionalLabels.prometheus | string | `"kube-prometheus"` | Prometheus selector label |
| controller.serviceMonitor.enabled | bool | `true` | Create ServiceMonitor for controller metrics |
| controller.workflowDefaults | object | `{"spec":{"podGC":{"deleteDelayDuration":"60s","strategy":"OnPodCompletion"},"ttlStrategy":{"secondsAfterCompletion":3600,"secondsAfterFailure":7200,"secondsAfterSuccess":1800}}}` | Default TTL strategy for completed workflows. |
| controller.workflowDefaults.spec.podGC | object | `{"deleteDelayDuration":"60s","strategy":"OnPodCompletion"}` | Garbage collection strategy for completed pods. |
| controller.workflowDefaults.spec.podGC.deleteDelayDuration | string | `"60s"` | Delay before deleting completed pods |
| controller.workflowDefaults.spec.podGC.strategy | string | `"OnPodCompletion"` | Pod GC strategy |
| controller.workflowDefaults.spec.ttlStrategy.secondsAfterCompletion | int | `3600` | TTL after completion (seconds) |
| controller.workflowDefaults.spec.ttlStrategy.secondsAfterFailure | int | `7200` | TTL after failure (seconds) |
| controller.workflowDefaults.spec.ttlStrategy.secondsAfterSuccess | int | `1800` | TTL after success (seconds) |
| controller.workflowEvents | object | `{"enabled":true}` | Enable workflow events. |
| controller.workflowEvents.enabled | bool | `true` | Emit workflow lifecycle events |
| controller.workflowNamespaces | list | `["cicd"]` | Namespaces where the controller will manage workflows. |
| controller.workflowRestrictions | object | `{"templateReferencing":"Strict"}` | Restrict template referencing to be within the same namespace. |
| controller.workflowRestrictions.templateReferencing | string | `"Strict"` | Template reference mode |
| crds.install | bool | `true` | Install and manage CRDs. |
| crds.keep | bool | `true` | Keep CRDs on chart uninstall. |
| executor.resources | object | `{"limits":{"cpu":"250m","memory":"128Mi"},"requests":{"cpu":"50m","memory":"64Mi"}}` | Resource requests and limits for the executor. |
| executor.resources.limits.cpu | string | `"250m"` | CPU limit for workflow executors |
| executor.resources.limits.memory | string | `"128Mi"` | Memory limit for workflow executors |
| executor.resources.requests.cpu | string | `"50m"` | CPU request for workflow executors |
| executor.resources.requests.memory | string | `"64Mi"` | Memory request for workflow executors |
| server.authModes | list | `["server"]` | Authentication modes for the server. |
| server.enabled | bool | `true` | Enable the controller server component |
| server.priorityClassName | string | `"platform-cicd"` | Priority class for the server pod. |
| server.rbac | object | `{"create":true}` | Create RBAC resources for the server. |
| server.rbac.create | bool | `true` | Create RBAC for the server deployment |
| server.resources | object | `{"limits":{"cpu":"250m","memory":"256Mi"},"requests":{"cpu":"50m","memory":"128Mi"}}` | Resource requests and limits for the server. |
| server.resources.limits.cpu | string | `"250m"` | CPU limit for the server |
| server.resources.limits.memory | string | `"256Mi"` | Memory limit for the server |
| server.resources.requests.cpu | string | `"50m"` | CPU request for the server |
| server.resources.requests.memory | string | `"128Mi"` | Memory request for the server |
| server.secure | bool | `false` | Require TLS on the server pod |
| server.serviceAccount | object | `{"create":true,"name":"argo-workflow-server"}` | Service account for the server. |
| server.serviceAccount.create | bool | `true` | Create the server service account |
| server.serviceAccount.name | string | `"argo-workflow-server"` | Service account name for the server |
| server.sso | object | `{"enabled":false}` | Enable Single Sign-On (SSO). |
| server.sso.enabled | bool | `false` | Enable SSO integration |
| workflow.rbac | object | `{"create":true,"rules":[{"apiGroups":[""],"resources":["secrets"],"verbs":["get"]}]}` | RBAC resources for workflows. |
| workflow.rbac.create | bool | `true` | Create workflow RBAC resources |
| workflow.serviceAccount | object | `{"create":true,"name":"argo-workflow"}` | Service account for workflows. |
| workflow.serviceAccount.create | bool | `true` | Create workflow service account |
| workflow.serviceAccount.name | string | `"argo-workflow"` | Workflow service account name |
| workflowDefaults.spec.priorityClassName | string | `"cicd-execution"` | Priority class for workflow pods. |
| workflowDefaults.spec.serviceAccountName | string | `"argo-workflow"` | Service account for workflow pods. |

