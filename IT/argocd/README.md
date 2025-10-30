# argocd

This document lists the configuration parameters for the `argocd` component.

## Values

### ApplicationSet

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| applicationSet | object | `{"enabled":true,"metrics":{"enabled":true,"serviceMonitor":{"enabled":true,"interval":"60s","scrapeTimeout":"40s"}},"priorityClassName":"platform-infrastructure","resources":{"limits":{"cpu":"250m","memory":"512Mi"},"requests":{"cpu":"125m","memory":"256Mi"}}}` | ApplicationSet controller for GitOps automation |

### TLS

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| certificate | object | `{"enabled":false,"format":"json","level":"warn"}` | Certificate management configuration |

### Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| configs | object | `{"cm":{"admin.enabled":true,"application.resourceTrackingMethod":"annotation","exec.enabled":true,"kustomize.buildOptions":"--enable-helm","resource.exclusions":"### Network resources created by the Kubernetes control plane and excluded to reduce the number of watched events and UI clutter\n- apiGroups:\n  - ''\n  - discovery.k8s.io\n  kinds:\n  - Endpoints\n  - EndpointSlice\n### Internal Kubernetes resources excluded reduce the number of watched events\n- apiGroups:\n  - coordination.k8s.io\n  kinds:\n  - Lease\n### Internal Kubernetes Authz/Authn resources excluded reduce the number of watched events\n- apiGroups:\n  - authentication.k8s.io\n  - authorization.k8s.io\n  kinds:\n  - SelfSubjectReview\n  - TokenReview\n  - LocalSubjectAccessReview\n  - SelfSubjectAccessReview\n  - SelfSubjectRulesReview\n  - SubjectAccessReview\n### Intermediate Certificate Request excluded reduce the number of watched events\n- apiGroups:\n  - certificates.k8s.io\n  kinds:\n  - CertificateSigningRequest\n- apiGroups:\n  - cert-manager.io\n  kinds:\n  - CertificateRequest\n### Cilium internal resources excluded reduce the number of watched events and UI Clutter\n- apiGroups:\n  - cilium.io\n  kinds:\n  - CiliumIdentity\n  - CiliumEndpoint\n  - CiliumEndpointSlice\n### Kyverno intermediate and reporting resources excluded reduce the number of watched events and improve performance\n- apiGroups:\n  - kyverno.io\n  - reports.kyverno.io\n  - wgpolicyk8s.io\n  kinds:\n  - PolicyReport\n  - ClusterPolicyReport\n  - EphemeralReport\n  - ClusterEphemeralReport\n  - AdmissionReport\n  - ClusterAdmissionReport\n  - BackgroundScanReport\n  - ClusterBackgroundScanReport\n  - UpdateRequest\n","statusbadge.enabled":true,"timeout.reconciliation":"180s"},"repositories":{"aqua":{"name":"aqua","type":"helm","url":"https://aquasecurity.github.io/helm-charts/"},"argo-project":{"name":"argo-project","type":"helm","url":"https://argoproj.github.io/argo-helm"},"bitnami":{"name":"bitnami","type":"helm","url":"https://charts.bitnami.com/bitnami"},"cilium":{"name":"cilium","type":"helm","url":"https://helm.cilium.io/"},"external-secrets":{"name":"external-secrets","type":"helm","url":"https://charts.external-secrets.io"},"fluent":{"name":"fluent","type":"helm","url":"https://fluent.github.io/helm-charts"},"grafana":{"name":"grafana","type":"helm","url":"https://grafana.github.io/helm-charts"},"hashicorp":{"name":"hashicorp","type":"helm","url":"https://helm.releases.hashicorp.com"},"jetstack":{"name":"jetstack","type":"helm","url":"https://charts.jetstack.io/"},"kyverno":{"name":"kyverno","type":"helm","url":"https://kyverno.github.io/kyverno/"},"open-telemetry":{"name":"open-telemetry","type":"helm","url":"https://open-telemetry.github.io/opentelemetry-helm-charts"},"pixie-operator":{"name":"pixie-operator","type":"helm","url":"https://artifacts.px.dev/helm_charts/operator"},"policy-reporter":{"name":"policy-reporter","type":"helm","url":"https://kyverno.github.io/policy-reporter"},"prometheus-community":{"name":"prometheus-community","type":"helm","url":"https://prometheus-community.github.io/helm-charts"},"sonarsource":{"name":"sonarsource","type":"helm","url":"https://SonarSource.github.io/helm-chart-sonarqube"}},"secret":{"argocdServerAdminPassword":"$2a$10$tYFiS1qMKY8rUMgc/a31TO19Rhg7auvSye9Vx8opYY/8rnUwfTaSO","createSecret":true}}` | ArgoCD configuration and secrets |

### Repositories

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| configs.repositories | object | `{"aqua":{"name":"aqua","type":"helm","url":"https://aquasecurity.github.io/helm-charts/"},"argo-project":{"name":"argo-project","type":"helm","url":"https://argoproj.github.io/argo-helm"},"bitnami":{"name":"bitnami","type":"helm","url":"https://charts.bitnami.com/bitnami"},"cilium":{"name":"cilium","type":"helm","url":"https://helm.cilium.io/"},"external-secrets":{"name":"external-secrets","type":"helm","url":"https://charts.external-secrets.io"},"fluent":{"name":"fluent","type":"helm","url":"https://fluent.github.io/helm-charts"},"grafana":{"name":"grafana","type":"helm","url":"https://grafana.github.io/helm-charts"},"hashicorp":{"name":"hashicorp","type":"helm","url":"https://helm.releases.hashicorp.com"},"jetstack":{"name":"jetstack","type":"helm","url":"https://charts.jetstack.io/"},"kyverno":{"name":"kyverno","type":"helm","url":"https://kyverno.github.io/kyverno/"},"open-telemetry":{"name":"open-telemetry","type":"helm","url":"https://open-telemetry.github.io/opentelemetry-helm-charts"},"pixie-operator":{"name":"pixie-operator","type":"helm","url":"https://artifacts.px.dev/helm_charts/operator"},"policy-reporter":{"name":"policy-reporter","type":"helm","url":"https://kyverno.github.io/policy-reporter"},"prometheus-community":{"name":"prometheus-community","type":"helm","url":"https://prometheus-community.github.io/helm-charts"},"sonarsource":{"name":"sonarsource","type":"helm","url":"https://SonarSource.github.io/helm-chart-sonarqube"}}` | Helm repository configuration |

### Controller

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| controller | object | `{"metrics":{"enabled":true,"serviceMonitor":{"enabled":true,"interval":"30s","scrapeTimeout":"25s"}},"priorityClassName":"platform-infrastructure","resources":{"limits":{"cpu":"1000m","memory":"1Gi"},"requests":{"cpu":"250m","memory":"512Mi"}}}` | ArgoCD controller configuration for application reconciliation |

### CRDs

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| crds | object | `{"install":true,"keep":true}` | Custom Resource Definitions |

### RBAC

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| createClusterRoles | bool | `true` | Create cluster roles for ArgoCD |

### Authentication

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| dex | object | `{"enabled":false}` | Dex configuration for SSO |

### High Availability

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ha | object | `{"enabled":false}` | High Availability configuration |

### Redis

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| redis | object | `{"resources":{"limits":{"cpu":"250m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}}` | Redis cache configuration |

### Repository Server

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| repoServer | object | `{"metrics":{"enabled":true,"serviceMonitor":{"enabled":true,"interval":"60s","scrapeTimeout":"40s"}},"priorityClassName":"platform-infrastructure","resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"250m","memory":"256Mi"}}}` | Repository server configuration for Git operations |

### Server

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| server | object | `{"ingress":{"enabled":false,"tls":false},"metrics":{"enabled":true,"serviceMonitor":{"enabled":true,"interval":"30s","scrapeTimeout":"25s"}},"priorityClassName":"platform-infrastructure","resources":{"limits":{"cpu":"250m","memory":"256Mi"},"requests":{"cpu":"125m","memory":"128Mi"}}}` | ArgoCD API server configuration |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| applicationSet.enabled | bool | `true` | Enable ApplicationSet controller |
| applicationSet.metrics | object | `{"enabled":true,"serviceMonitor":{"enabled":true,"interval":"60s","scrapeTimeout":"40s"}}` | Metrics configuration |
| applicationSet.metrics.enabled | bool | `true` | Enable metrics |
| applicationSet.metrics.serviceMonitor | object | `{"enabled":true,"interval":"60s","scrapeTimeout":"40s"}` | ServiceMonitor configuration |
| applicationSet.metrics.serviceMonitor.enabled | bool | `true` | Enable ServiceMonitor |
| applicationSet.metrics.serviceMonitor.interval | string | `"60s"` | Scrape interval for template rendering |
| applicationSet.metrics.serviceMonitor.scrapeTimeout | string | `"40s"` | Scrape timeout |
| applicationSet.priorityClassName | string | `"platform-infrastructure"` | Priority class |
| applicationSet.resources | object | `{"limits":{"cpu":"250m","memory":"512Mi"},"requests":{"cpu":"125m","memory":"256Mi"}}` | Resource limits and requests |
| applicationSet.resources.limits | object | `{"cpu":"250m","memory":"512Mi"}` | Resource limits |
| applicationSet.resources.limits.cpu | string | `"250m"` | CPU limit |
| applicationSet.resources.limits.memory | string | `"512Mi"` | Memory limit |
| applicationSet.resources.requests | object | `{"cpu":"125m","memory":"256Mi"}` | Resource requests |
| applicationSet.resources.requests.cpu | string | `"125m"` | CPU request |
| applicationSet.resources.requests.memory | string | `"256Mi"` | Memory request |
| certificate.enabled | bool | `false` | Enable certificate management (handled by cert-manager) |
| certificate.format | string | `"json"` | Global logging format |
| certificate.level | string | `"warn"` | Global logging level |
| configs.cm | object | `{"admin.enabled":true,"application.resourceTrackingMethod":"annotation","exec.enabled":true,"kustomize.buildOptions":"--enable-helm","resource.exclusions":"### Network resources created by the Kubernetes control plane and excluded to reduce the number of watched events and UI clutter\n- apiGroups:\n  - ''\n  - discovery.k8s.io\n  kinds:\n  - Endpoints\n  - EndpointSlice\n### Internal Kubernetes resources excluded reduce the number of watched events\n- apiGroups:\n  - coordination.k8s.io\n  kinds:\n  - Lease\n### Internal Kubernetes Authz/Authn resources excluded reduce the number of watched events\n- apiGroups:\n  - authentication.k8s.io\n  - authorization.k8s.io\n  kinds:\n  - SelfSubjectReview\n  - TokenReview\n  - LocalSubjectAccessReview\n  - SelfSubjectAccessReview\n  - SelfSubjectRulesReview\n  - SubjectAccessReview\n### Intermediate Certificate Request excluded reduce the number of watched events\n- apiGroups:\n  - certificates.k8s.io\n  kinds:\n  - CertificateSigningRequest\n- apiGroups:\n  - cert-manager.io\n  kinds:\n  - CertificateRequest\n### Cilium internal resources excluded reduce the number of watched events and UI Clutter\n- apiGroups:\n  - cilium.io\n  kinds:\n  - CiliumIdentity\n  - CiliumEndpoint\n  - CiliumEndpointSlice\n### Kyverno intermediate and reporting resources excluded reduce the number of watched events and improve performance\n- apiGroups:\n  - kyverno.io\n  - reports.kyverno.io\n  - wgpolicyk8s.io\n  kinds:\n  - PolicyReport\n  - ClusterPolicyReport\n  - EphemeralReport\n  - ClusterEphemeralReport\n  - AdmissionReport\n  - ClusterAdmissionReport\n  - BackgroundScanReport\n  - ClusterBackgroundScanReport\n  - UpdateRequest\n","statusbadge.enabled":true,"timeout.reconciliation":"180s"}` | ConfigMap configuration |
| configs.cm."admin.enabled" | bool | `true` | Enable local admin user |
| configs.cm."application.resourceTrackingMethod" | string | `"annotation"` | Resource tracking method for performance |
| configs.cm."exec.enabled" | bool | `true` | Enable exec feature in Argo UI |
| configs.cm."kustomize.buildOptions" | string | `"--enable-helm"` | Enable Helm support in Kustomize builds |
| configs.cm."resource.exclusions" | string | `"### Network resources created by the Kubernetes control plane and excluded to reduce the number of watched events and UI clutter\n- apiGroups:\n  - ''\n  - discovery.k8s.io\n  kinds:\n  - Endpoints\n  - EndpointSlice\n### Internal Kubernetes resources excluded reduce the number of watched events\n- apiGroups:\n  - coordination.k8s.io\n  kinds:\n  - Lease\n### Internal Kubernetes Authz/Authn resources excluded reduce the number of watched events\n- apiGroups:\n  - authentication.k8s.io\n  - authorization.k8s.io\n  kinds:\n  - SelfSubjectReview\n  - TokenReview\n  - LocalSubjectAccessReview\n  - SelfSubjectAccessReview\n  - SelfSubjectRulesReview\n  - SubjectAccessReview\n### Intermediate Certificate Request excluded reduce the number of watched events\n- apiGroups:\n  - certificates.k8s.io\n  kinds:\n  - CertificateSigningRequest\n- apiGroups:\n  - cert-manager.io\n  kinds:\n  - CertificateRequest\n### Cilium internal resources excluded reduce the number of watched events and UI Clutter\n- apiGroups:\n  - cilium.io\n  kinds:\n  - CiliumIdentity\n  - CiliumEndpoint\n  - CiliumEndpointSlice\n### Kyverno intermediate and reporting resources excluded reduce the number of watched events and improve performance\n- apiGroups:\n  - kyverno.io\n  - reports.kyverno.io\n  - wgpolicyk8s.io\n  kinds:\n  - PolicyReport\n  - ClusterPolicyReport\n  - EphemeralReport\n  - ClusterEphemeralReport\n  - AdmissionReport\n  - ClusterAdmissionReport\n  - BackgroundScanReport\n  - ClusterBackgroundScanReport\n  - UpdateRequest\n"` | Exclude high-frequency resources from reconciliation |
| configs.cm."statusbadge.enabled" | string | `true` | Enable status badges |
| configs.cm."timeout.reconciliation" | string | `"180s"` | Timeout to discover new manifest versions |
| configs.repositories.aqua | object | `{"name":"aqua","type":"helm","url":"https://aquasecurity.github.io/helm-charts/"}` | Aqua Security Helm repository |
| configs.repositories.aqua.name | string | `"aqua"` | Repository name |
| configs.repositories.aqua.type | string | `"helm"` | Repository type |
| configs.repositories.aqua.url | string | `"https://aquasecurity.github.io/helm-charts/"` | Repository URL |
| configs.repositories.argo-project | object | `{"name":"argo-project","type":"helm","url":"https://argoproj.github.io/argo-helm"}` | Argo Project Helm repository |
| configs.repositories.argo-project.name | string | `"argo-project"` | Repository name |
| configs.repositories.argo-project.type | string | `"helm"` | Repository type |
| configs.repositories.argo-project.url | string | `"https://argoproj.github.io/argo-helm"` | Repository URL |
| configs.repositories.bitnami | object | `{"name":"bitnami","type":"helm","url":"https://charts.bitnami.com/bitnami"}` | Bitnami Helm repository |
| configs.repositories.bitnami.name | string | `"bitnami"` | Repository name |
| configs.repositories.bitnami.type | string | `"helm"` | Repository type |
| configs.repositories.bitnami.url | string | `"https://charts.bitnami.com/bitnami"` | Repository URL |
| configs.repositories.cilium | object | `{"name":"cilium","type":"helm","url":"https://helm.cilium.io/"}` | Cilium Helm repository |
| configs.repositories.cilium.name | string | `"cilium"` | Repository name |
| configs.repositories.cilium.type | string | `"helm"` | Repository type |
| configs.repositories.cilium.url | string | `"https://helm.cilium.io/"` | Repository URL |
| configs.repositories.external-secrets | object | `{"name":"external-secrets","type":"helm","url":"https://charts.external-secrets.io"}` | External Secrets Helm repository |
| configs.repositories.external-secrets.name | string | `"external-secrets"` | Repository name |
| configs.repositories.external-secrets.type | string | `"helm"` | Repository type |
| configs.repositories.external-secrets.url | string | `"https://charts.external-secrets.io"` | Repository URL |
| configs.repositories.fluent | object | `{"name":"fluent","type":"helm","url":"https://fluent.github.io/helm-charts"}` | Fluent Helm repository |
| configs.repositories.fluent.name | string | `"fluent"` | Repository name |
| configs.repositories.fluent.type | string | `"helm"` | Repository type |
| configs.repositories.fluent.url | string | `"https://fluent.github.io/helm-charts"` | Repository URL |
| configs.repositories.grafana | object | `{"name":"grafana","type":"helm","url":"https://grafana.github.io/helm-charts"}` | Grafana Helm repository |
| configs.repositories.grafana.name | string | `"grafana"` | Repository name |
| configs.repositories.grafana.type | string | `"helm"` | Repository type |
| configs.repositories.grafana.url | string | `"https://grafana.github.io/helm-charts"` | Repository URL |
| configs.repositories.hashicorp | object | `{"name":"hashicorp","type":"helm","url":"https://helm.releases.hashicorp.com"}` | HashiCorp Helm repository |
| configs.repositories.hashicorp.name | string | `"hashicorp"` | Repository name |
| configs.repositories.hashicorp.type | string | `"helm"` | Repository type |
| configs.repositories.hashicorp.url | string | `"https://helm.releases.hashicorp.com"` | Repository URL |
| configs.repositories.jetstack | object | `{"name":"jetstack","type":"helm","url":"https://charts.jetstack.io/"}` | Jetstack Helm repository |
| configs.repositories.jetstack.name | string | `"jetstack"` | Repository name |
| configs.repositories.jetstack.type | string | `"helm"` | Repository type |
| configs.repositories.jetstack.url | string | `"https://charts.jetstack.io/"` | Repository URL |
| configs.repositories.kyverno | object | `{"name":"kyverno","type":"helm","url":"https://kyverno.github.io/kyverno/"}` | Kyverno Helm repository |
| configs.repositories.kyverno.name | string | `"kyverno"` | Repository name |
| configs.repositories.kyverno.type | string | `"helm"` | Repository type |
| configs.repositories.kyverno.url | string | `"https://kyverno.github.io/kyverno/"` | Repository URL |
| configs.repositories.open-telemetry | object | `{"name":"open-telemetry","type":"helm","url":"https://open-telemetry.github.io/opentelemetry-helm-charts"}` | OpenTelemetry Helm repository |
| configs.repositories.open-telemetry.name | string | `"open-telemetry"` | Repository name |
| configs.repositories.open-telemetry.type | string | `"helm"` | Repository type |
| configs.repositories.open-telemetry.url | string | `"https://open-telemetry.github.io/opentelemetry-helm-charts"` | Repository URL |
| configs.repositories.pixie-operator | object | `{"name":"pixie-operator","type":"helm","url":"https://artifacts.px.dev/helm_charts/operator"}` | Pixie Operator Helm repository |
| configs.repositories.pixie-operator.name | string | `"pixie-operator"` | Repository name |
| configs.repositories.pixie-operator.type | string | `"helm"` | Repository type |
| configs.repositories.pixie-operator.url | string | `"https://artifacts.px.dev/helm_charts/operator"` | Repository URL |
| configs.repositories.policy-reporter | object | `{"name":"policy-reporter","type":"helm","url":"https://kyverno.github.io/policy-reporter"}` | Policy Reporter Helm repository |
| configs.repositories.policy-reporter.name | string | `"policy-reporter"` | Repository name |
| configs.repositories.policy-reporter.type | string | `"helm"` | Repository type |
| configs.repositories.policy-reporter.url | string | `"https://kyverno.github.io/policy-reporter"` | Repository URL |
| configs.repositories.prometheus-community | object | `{"name":"prometheus-community","type":"helm","url":"https://prometheus-community.github.io/helm-charts"}` | Prometheus Community Helm repository |
| configs.repositories.prometheus-community.name | string | `"prometheus-community"` | Repository name |
| configs.repositories.prometheus-community.type | string | `"helm"` | Repository type |
| configs.repositories.prometheus-community.url | string | `"https://prometheus-community.github.io/helm-charts"` | Repository URL |
| configs.repositories.sonarsource | object | `{"name":"sonarsource","type":"helm","url":"https://SonarSource.github.io/helm-chart-sonarqube"}` | SonarSource Helm repository |
| configs.repositories.sonarsource.name | string | `"sonarsource"` | Repository name |
| configs.repositories.sonarsource.type | string | `"helm"` | Repository type |
| configs.repositories.sonarsource.url | string | `"https://SonarSource.github.io/helm-chart-sonarqube"` | Repository URL |
| configs.secret | object | `{"argocdServerAdminPassword":"$2a$10$tYFiS1qMKY8rUMgc/a31TO19Rhg7auvSye9Vx8opYY/8rnUwfTaSO","createSecret":true}` | Secret configuration |
| configs.secret.argocdServerAdminPassword | string | Vault-generated bcrypt hash | Admin password hash (managed by Vault) |
| configs.secret.createSecret | bool | `true` | Create secret for admin credentials |
| controller.metrics | object | `{"enabled":true,"serviceMonitor":{"enabled":true,"interval":"30s","scrapeTimeout":"25s"}}` | Metrics configuration |
| controller.metrics.enabled | bool | `true` | Enable Prometheus metrics |
| controller.metrics.serviceMonitor | object | `{"enabled":true,"interval":"30s","scrapeTimeout":"25s"}` | ServiceMonitor configuration |
| controller.metrics.serviceMonitor.enabled | bool | `true` | Enable ServiceMonitor for Prometheus Operator |
| controller.metrics.serviceMonitor.interval | string | `"30s"` | Scrape interval for GitOps reconciliation tracking |
| controller.metrics.serviceMonitor.scrapeTimeout | string | `"25s"` | Scrape timeout |
| controller.priorityClassName | string | `"platform-infrastructure"` | Priority class for controller pods |
| controller.resources | object | `{"limits":{"cpu":"1000m","memory":"1Gi"},"requests":{"cpu":"250m","memory":"512Mi"}}` | Resource limits and requests for controller |
| controller.resources.limits | object | `{"cpu":"1000m","memory":"1Gi"}` | Resource limits |
| controller.resources.limits.cpu | string | `"1000m"` | CPU limit |
| controller.resources.limits.memory | string | `"1Gi"` | Memory limit |
| controller.resources.requests | object | `{"cpu":"250m","memory":"512Mi"}` | Resource requests |
| controller.resources.requests.cpu | string | `"250m"` | CPU request |
| controller.resources.requests.memory | string | `"512Mi"` | Memory request |
| crds.install | bool | `true` | Install CRDs |
| crds.keep | bool | `true` | Keep CRDs on chart uninstall |
| dex.enabled | bool | `false` | Enable Dex federated OpenID Connect provider |
| ha.enabled | bool | `false` | Enable High Availability mode for production deployments |
| redis.resources | object | `{"limits":{"cpu":"250m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Resource limits and requests |
| redis.resources.limits | object | `{"cpu":"250m","memory":"256Mi"}` | Resource limits |
| redis.resources.limits.cpu | string | `"250m"` | CPU limit |
| redis.resources.limits.memory | string | `"256Mi"` | Memory limit |
| redis.resources.requests | object | `{"cpu":"100m","memory":"128Mi"}` | Resource requests |
| redis.resources.requests.cpu | string | `"100m"` | CPU request |
| redis.resources.requests.memory | string | `"128Mi"` | Memory request |
| repoServer.metrics | object | `{"enabled":true,"serviceMonitor":{"enabled":true,"interval":"60s","scrapeTimeout":"40s"}}` | Metrics configuration |
| repoServer.metrics.enabled | bool | `true` | Enable metrics |
| repoServer.metrics.serviceMonitor | object | `{"enabled":true,"interval":"60s","scrapeTimeout":"40s"}` | ServiceMonitor configuration |
| repoServer.metrics.serviceMonitor.enabled | bool | `true` | Enable ServiceMonitor |
| repoServer.metrics.serviceMonitor.interval | string | `"60s"` | Scrape interval for background git operations |
| repoServer.metrics.serviceMonitor.scrapeTimeout | string | `"40s"` | Scrape timeout |
| repoServer.priorityClassName | string | `"platform-infrastructure"` | Priority class |
| repoServer.resources | object | `{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"250m","memory":"256Mi"}}` | Resource limits and requests |
| repoServer.resources.limits | object | `{"cpu":"500m","memory":"512Mi"}` | Resource limits |
| repoServer.resources.limits.cpu | string | `"500m"` | CPU limit |
| repoServer.resources.limits.memory | string | `"512Mi"` | Memory limit |
| repoServer.resources.requests | object | `{"cpu":"250m","memory":"256Mi"}` | Resource requests |
| repoServer.resources.requests.cpu | string | `"250m"` | CPU request |
| repoServer.resources.requests.memory | string | `"256Mi"` | Memory request |
| server.ingress | object | `{"enabled":false,"tls":false}` | Ingress configuration |
| server.ingress.enabled | bool | `false` | Enable ingress |
| server.ingress.tls | bool | `false` | Enable TLS |
| server.metrics | object | `{"enabled":true,"serviceMonitor":{"enabled":true,"interval":"30s","scrapeTimeout":"25s"}}` | Metrics configuration |
| server.metrics.enabled | bool | `true` | Enable metrics |
| server.metrics.serviceMonitor | object | `{"enabled":true,"interval":"30s","scrapeTimeout":"25s"}` | ServiceMonitor configuration |
| server.metrics.serviceMonitor.enabled | bool | `true` | Enable ServiceMonitor |
| server.metrics.serviceMonitor.interval | string | `"30s"` | Scrape interval for user-facing API latency |
| server.metrics.serviceMonitor.scrapeTimeout | string | `"25s"` | Scrape timeout |
| server.priorityClassName | string | `"platform-infrastructure"` | Priority class for server pods |
| server.resources | object | `{"limits":{"cpu":"250m","memory":"256Mi"},"requests":{"cpu":"125m","memory":"128Mi"}}` | Resource limits and requests |
| server.resources.limits | object | `{"cpu":"250m","memory":"256Mi"}` | Resource limits |
| server.resources.limits.cpu | string | `"250m"` | CPU limit |
| server.resources.limits.memory | string | `"256Mi"` | Memory limit |
| server.resources.requests | object | `{"cpu":"125m","memory":"128Mi"}` | Resource requests |
| server.resources.requests.cpu | string | `"125m"` | CPU request |
| server.resources.requests.memory | string | `"128Mi"` | Memory request |