# argo-workflows

![Version: 0.45.27](https://img.shields.io/badge/Version-0.45.27-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  [![Homepage](https://img.shields.io/badge/Homepage-blue)](https://argoproj.github.io/workflows)

Kubernetes-native workflow engine for orchestrating parallel jobs

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `0.45.27` |
| **Chart Type** | `application` |
| **Upstream Project** | [argo-workflows](https://argoproj.github.io/workflows) |
| **Maintainers** | Platform Engineering Team ([link](https://github.com/rou-cru/idp-blueprint)) |

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
| controller.metricsConfig | object | `{"enabled":true}` | Enable Prometheus metrics endpoint. |
| controller.nodeEvents | object | `{"enabled":true}` | Enable node events for workflows. |
| controller.parallelism | int | `10` | Maximum number of parallel workflows. |
| controller.persistence | object | `{"archive":false,"connectionPool":{"maxIdleConns":0,"maxOpenConns":0}}` | Persistence configuration for the controller. Completely disable archive and persistence for k3d environment |
| controller.priorityClassName | string | `"platform-cicd"` | Priority class for the controller pod. |
| controller.rbac | object | `{"create":true}` | Create RBAC resources for the controller. |
| controller.resources | object | `{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}}` | Resource requests and limits for the controller. |
| controller.retentionPolicy | object | `{"completed":10,"errored":5,"failed":5}` | Retention policy for completed workflows. |
| controller.serviceAccount | object | `{"create":true,"name":"argo-workflow-controller"}` | Service account for the controller. |
| controller.serviceMonitor | object | `{"additionalLabels":{"prometheus":"kube-prometheus"},"enabled":true}` | Create a ServiceMonitor for Prometheus. |
| controller.workflowDefaults | object | `{"spec":{"podGC":{"deleteDelayDuration":"60s","strategy":"OnPodCompletion"},"ttlStrategy":{"secondsAfterCompletion":3600,"secondsAfterFailure":7200,"secondsAfterSuccess":1800}}}` | Default TTL strategy for completed workflows. |
| controller.workflowDefaults.spec.podGC | object | `{"deleteDelayDuration":"60s","strategy":"OnPodCompletion"}` | Garbage collection strategy for completed pods. |
| controller.workflowEvents | object | `{"enabled":true}` | Enable workflow events. |
| controller.workflowNamespaces | list | `["cicd"]` | Namespaces where the controller will manage workflows. |
| controller.workflowRestrictions | object | `{"templateReferencing":"Strict"}` | Restrict template referencing to be within the same namespace. |
| crds.install | bool | `true` | Install and manage CRDs. |
| crds.keep | bool | `true` | Keep CRDs on chart uninstall. |
| executor.resources | object | `{"limits":{"cpu":"250m","memory":"128Mi"},"requests":{"cpu":"50m","memory":"64Mi"}}` | Resource requests and limits for the executor. |
| server.authModes | list | `["server"]` | Authentication modes for the server. |
| server.enabled | bool | `true` | Enable the Argo Workflows server. Required for web UI and API access |
| server.priorityClassName | string | `"platform-cicd"` | Priority class for the server pod. |
| server.rbac | object | `{"create":true}` | Create RBAC resources for the server. |
| server.resources | object | `{"limits":{"cpu":"250m","memory":"256Mi"},"requests":{"cpu":"50m","memory":"128Mi"}}` | Resource requests and limits for the server. |
| server.secure | bool | `false` | Secure mode disabled when behind TLS-terminating gateway The Gateway handles TLS, so the server receives plain HTTP |
| server.serviceAccount | object | `{"create":true,"name":"argo-workflow-server"}` | Service account for the server. |
| server.sso | object | `{"enabled":false}` | Enable Single Sign-On (SSO). |
| workflow.rbac | object | `{"create":true,"rules":[{"apiGroups":[""],"resources":["secrets"],"verbs":["get"]}]}` | RBAC resources for workflows. |
| workflow.serviceAccount | object | `{"create":true,"name":"argo-workflow"}` | Service account for workflows. |
| workflowDefaults.spec.priorityClassName | string | `"cicd-execution"` | Priority class for workflow pods. |
| workflowDefaults.spec.serviceAccountName | string | `"argo-workflow"` | Service account for workflow pods. |

---

**Documentation Auto-generated** by [helm-docs](https://github.com/norwoodj/helm-docs)
**Last Updated**: This file is regenerated automatically when values change
