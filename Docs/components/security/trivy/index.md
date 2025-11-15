# trivy

![Version: 0.31.0](https://img.shields.io/badge/Version-0.31.0-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  [![Homepage](https://img.shields.io/badge/Homepage-blue)](https://trivy.dev)

Comprehensive security scanner for vulnerabilities and misconfigurations

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `0.31.0` |
| **Chart Type** | `application` |
| **Upstream Project** | [trivy](https://trivy.dev) |
| **Maintainers** | Platform Engineering Team ([link](https://github.com/rou-cru/idp-blueprint)) |

## Why Trivy?

Trivy scans container images for vulnerabilities, misconfigurations, and secrets. It's comprehensive, fast, and can run in CI pipelines or as an operator in-cluster.

Trivy supports multiple scan targets (container images, filesystems, Git repositories, Kubernetes resources) and outputs results in various formats. It integrates with CI/CD workflows to block deployments of vulnerable images.

In this platform, Trivy can scan images during the build phase (in Argo Workflows) and periodically scan running workloads for newly discovered vulnerabilities.

## Architecture Role

Trivy operates at **Layer 3** of the platform, part of the security tooling.

Key integration points:

- **Argo Workflows**: Workflows can trigger Trivy scans as part of CI
- **Container Registry**: Scans images from the registry
- **Kubernetes API**: Can scan deployed resources for misconfigurations
- **PolicyReports**: Can generate PolicyReport CRDs for tracking scan results

Trivy runs as an operator that periodically scans resources and reports findings.

## Configuration Values

The following table lists the configurable parameters:

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

---

**Documentation Auto-generated** by [helm-docs](https://github.com/norwoodj/helm-docs)
**Last Updated**: This file is regenerated automatically when values change
