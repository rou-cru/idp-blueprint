# trivy

This document lists the configuration parameters for the `trivy` component.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| compliance.enabled | bool | `true` | Enable compliance reporting |
| compliance.specs | list | `["k8s-pss-baseline-0.1"]` | Compliance specifications to run |
| excludeNamespaces | string | `"kube-system,argocd,cert-manager,vault-system,kyverno-system"` | Namespaces to be excluded from scanning |
| operator.clusterComplianceEnabled | bool | `true` | Enable cluster compliance scanner |
| operator.configAuditScannerEnabled | bool | `true` | Enable configuration audit scanner |
| operator.exposedSecretScannerEnabled | bool | `true` | Enable exposed secret scanner |
| operator.infraAssessmentScannerEnabled | bool | `false` | Disable infrastructure assessment scanner |
| operator.rbacAssessmentScannerEnabled | bool | `true` | Enable RBAC assessment scanner |
| operator.vulnerabilityScannerEnabled | bool | `true` | Enable vulnerability scanner |
| priorityClassName | string | `"platform-security"` | Priority class for Trivy pods |
| resources.limits.cpu | string | `"500m"` | CPU limit |
| resources.limits.memory | string | `"512Mi"` | Memory limit |
| resources.requests.cpu | string | `"100m"` | CPU request |
| resources.requests.memory | string | `"128Mi"` | Memory request |
| serviceMonitor.enabled | bool | `true` | Enable ServiceMonitor |
| serviceMonitor.honorLabels | bool | `true` | Honor labels on collisions |
| targetWorkloads | string | `"pod,replicaset,replicationcontroller,statefulset,daemonset,cronjob,job"` | Comma-separated list of target workloads |
| trivy.mode | string | `"ClientServer"` | Scanner mode |
| trivy.serverURL | string | `"http://trivy-server.security.svc:4954"` | Trivy Server URL |
| trivyServer.dbUpdateInterval | string | `"12h"` | Database update interval |
| trivyServer.enabled | bool | `true` | Enable Trivy Server deployment |
| trivyServer.persistence.enabled | bool | `true` | Enable persistence |
| trivyServer.persistence.size | string | `"1Gi"` | Storage size |
| trivyServer.persistence.storageClass | string | `"local-path"` | Storage class |
| trivyServer.resources.limits.cpu | string | `"1000m"` | CPU limit |
| trivyServer.resources.limits.memory | string | `"1Gi"` | Memory limit |
| trivyServer.resources.requests.cpu | string | `"200m"` | CPU request |
| trivyServer.resources.requests.memory | string | `"512Mi"` | Memory request |