# cilium

This document lists the configuration parameters for the `cilium` component.

## Values

### BGP

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| bgpControlPlane | object | `{"enabled":false}` | BGP Control Plane configuration |

### Performance

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| bpf | object | `{"monitorAggregation":"medium","monitorFlags":"all","monitorInterval":"10s"}` | BPF performance settings |

### Cluster

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cluster | object | `{"id":1,"name":"idp-demo"}` | Cluster identification for multi-cluster scenarios |

### Labels

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| commonLabels | object | `{"app.kubernetes.io/component":"cni","app.kubernetes.io/instance":"cilium-demo","app.kubernetes.io/part-of":"idp","app.kubernetes.io/version":"1.18.2","business-unit":"engineering","environment":"demo","owner":"platform-engineer"}` | Custom labels for all resources |

### Security

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| encryption | object | `{"enabled":false,"type":"wireguard"}` | Encryption configuration |

### Gateway API

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| gatewayAPI | object | `{"enabled":true}` | Gateway API support for modern traffic routing |

### Hubble

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| hubble | object | `{"enabled":true,"metrics":{"enabled":["dns:query;ignoreAAAA","drop","tcp","flow","port-distribution","icmp","http"]},"relay":{"enabled":true,"replicas":1,"resources":{"limits":{"cpu":"500m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}},"ui":{"enabled":true,"ingress":{"enabled":false},"replicas":1,"resources":{"limits":{"cpu":"100m","memory":"128Mi"},"requests":{"cpu":"50m","memory":"64Mi"}},"service":{"type":"ClusterIP"}}}` | Hubble observability for network flow visibility |

### Ingress Controller

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ingressController | object | `{"default":true,"enabled":true,"loadbalancerMode":"shared","service":{"type":"LoadBalancer"}}` | Cilium Ingress Controller with eBPF |

### IPAM

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ipam | object | `{"mode":"cluster-pool","operator":{"clusterPoolIPv4PodCIDRList":["10.42.0.0/16"]}}` | IPAM configuration for pod IP address management |

### IPv6

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ipv6 | object | `{"enabled":false}` | IPv6 configuration |

### Kube-proxy Replacement

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kubeProxyReplacement | bool | `true` | Replace kube-proxy with Cilium's eBPF implementation |

### Operator

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| operator | object | `{"prometheus":{"enabled":true,"serviceMonitor":{"enabled":true,"interval":"30s","scrapeTimeout":"25s"}},"replicas":1,"resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}}` | Cilium operator configuration |

### Network Policy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| policyEnforcementMode | string | `"default"` | Default enforcement mode for CiliumNetworkPolicy |

### Observability

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| prometheus | object | `{"dashboards":{"enabled":true,"namespace":"default"},"enabled":true,"serviceMonitor":{"enabled":true,"interval":"30s","scrapeTimeout":"25s"}}` | Prometheus metrics configuration |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| bgpControlPlane.enabled | bool | `false` | Enable BGP (disabled for demo, used for on-prem route announcement) |
| bpf.monitorAggregation | string | `"medium"` | Monitor aggregation level |
| bpf.monitorFlags | string | `"all"` | Monitor flags |
| bpf.monitorInterval | string | `"10s"` | Monitor interval |
| cluster.id | int | `1` | Cluster ID |
| cluster.name | string | `"idp-demo"` | Cluster name |
| commonLabels."app.kubernetes.io/component" | string | `"cni"` | Application component |
| commonLabels."app.kubernetes.io/instance" | string | `"cilium-demo"` | Application instance |
| commonLabels."app.kubernetes.io/part-of" | string | `"idp"` | Part of platform |
| commonLabels."app.kubernetes.io/version" | string | `"1.18.2"` | Application version |
| commonLabels.business-unit | string | `"engineering"` | Business unit |
| commonLabels.environment | string | `"demo"` | Environment |
| commonLabels.owner | string | `"platform-engineer"` | Owner |
| encryption.enabled | bool | `false` | Enable encryption (disabled for local demo) |
| encryption.type | string | `"wireguard"` | Encryption type |
| gatewayAPI.enabled | bool | `true` | Enable Gateway API |
| hubble.enabled | bool | `true` | Enable Hubble |
| hubble.metrics | object | `{"enabled":["dns:query;ignoreAAAA","drop","tcp","flow","port-distribution","icmp","http"]}` | Hubble metrics configuration |
| hubble.metrics.enabled | list | `["dns:query;ignoreAAAA","drop","tcp","flow","port-distribution","icmp","http"]` | Enabled metrics for Hubble to collect |
| hubble.relay | object | `{"enabled":true,"replicas":1,"resources":{"limits":{"cpu":"500m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}}` | Hubble Relay aggregates data from all Hubble instances |
| hubble.relay.enabled | bool | `true` | Enable Hubble Relay |
| hubble.relay.replicas | int | `1` | Number of replicas |
| hubble.relay.resources | object | `{"limits":{"cpu":"500m","memory":"256Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Resource limits and requests |
| hubble.relay.resources.limits | object | `{"cpu":"500m","memory":"256Mi"}` | Resource limits |
| hubble.relay.resources.limits.cpu | string | `"500m"` | CPU limit |
| hubble.relay.resources.limits.memory | string | `"256Mi"` | Memory limit |
| hubble.relay.resources.requests | object | `{"cpu":"100m","memory":"128Mi"}` | Resource requests |
| hubble.relay.resources.requests.cpu | string | `"100m"` | CPU request |
| hubble.relay.resources.requests.memory | string | `"128Mi"` | Memory request |
| hubble.ui | object | `{"enabled":true,"ingress":{"enabled":false},"replicas":1,"resources":{"limits":{"cpu":"100m","memory":"128Mi"},"requests":{"cpu":"50m","memory":"64Mi"}},"service":{"type":"ClusterIP"}}` | Hubble UI provides graphical interface for network data |
| hubble.ui.enabled | bool | `true` | Enable Hubble UI |
| hubble.ui.ingress | object | `{"enabled":false}` | Ingress configuration (managed by ArgoCD) |
| hubble.ui.ingress.enabled | bool | `false` | Enable ingress |
| hubble.ui.replicas | int | `1` | Number of replicas |
| hubble.ui.resources | object | `{"limits":{"cpu":"100m","memory":"128Mi"},"requests":{"cpu":"50m","memory":"64Mi"}}` | Resource limits and requests |
| hubble.ui.resources.limits | object | `{"cpu":"100m","memory":"128Mi"}` | Resource limits |
| hubble.ui.resources.limits.cpu | string | `"100m"` | CPU limit |
| hubble.ui.resources.limits.memory | string | `"128Mi"` | Memory limit |
| hubble.ui.resources.requests | object | `{"cpu":"50m","memory":"64Mi"}` | Resource requests |
| hubble.ui.resources.requests.cpu | string | `"50m"` | CPU request |
| hubble.ui.resources.requests.memory | string | `"64Mi"` | Memory request |
| hubble.ui.service | object | `{"type":"ClusterIP"}` | Service configuration |
| hubble.ui.service.type | string | `"ClusterIP"` | Service type |
| ingressController.default | bool | `true` | Make this the default IngressClass |
| ingressController.enabled | bool | `true` | Enable the Ingress Controller |
| ingressController.loadbalancerMode | string | `"shared"` | Use shared service for all Ingresses |
| ingressController.service | object | `{"type":"LoadBalancer"}` | Service configuration |
| ingressController.service.type | string | `"LoadBalancer"` | Service type (k3d load balancer will handle this) |
| ipam.mode | string | `"cluster-pool"` | IPAM mode (cluster-pool recommended for efficient allocation) |
| ipam.operator | object | `{"clusterPoolIPv4PodCIDRList":["10.42.0.0/16"]}` | IPAM operator configuration |
| ipam.operator.clusterPoolIPv4PodCIDRList | list | `["10.42.0.0/16"]` | Pod CIDR for the cluster (must match k3d default) |
| ipv6.enabled | bool | `false` | Enable IPv6 support (disabled for demo performance) |
| operator.prometheus | object | `{"enabled":true,"serviceMonitor":{"enabled":true,"interval":"30s","scrapeTimeout":"25s"}}` | Prometheus metrics configuration |
| operator.prometheus.enabled | bool | `true` | Enable Prometheus metrics |
| operator.prometheus.serviceMonitor | object | `{"enabled":true,"interval":"30s","scrapeTimeout":"25s"}` | ServiceMonitor configuration |
| operator.prometheus.serviceMonitor.enabled | bool | `true` | Enable ServiceMonitor |
| operator.prometheus.serviceMonitor.interval | string | `"30s"` | Scrape interval for critical CNI metrics |
| operator.prometheus.serviceMonitor.scrapeTimeout | string | `"25s"` | Scrape timeout |
| operator.replicas | int | `1` | Number of replicas for the operator |
| operator.resources | object | `{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Resource limits and requests |
| operator.resources.limits | object | `{"cpu":"500m","memory":"512Mi"}` | Resource limits |
| operator.resources.limits.cpu | string | `"500m"` | CPU limit |
| operator.resources.limits.memory | string | `"512Mi"` | Memory limit |
| operator.resources.requests | object | `{"cpu":"100m","memory":"128Mi"}` | Resource requests |
| operator.resources.requests.cpu | string | `"100m"` | CPU request |
| operator.resources.requests.memory | string | `"128Mi"` | Memory request |
| prometheus.dashboards | object | `{"enabled":true,"namespace":"default"}` | Grafana dashboards configuration |
| prometheus.dashboards.enabled | bool | `true` | Create ConfigMap with official Cilium dashboard |
| prometheus.dashboards.namespace | string | `"default"` | Namespace for dashboard ConfigMap |
| prometheus.enabled | bool | `true` | Enable metrics exposition |
| prometheus.serviceMonitor | object | `{"enabled":true,"interval":"30s","scrapeTimeout":"25s"}` | ServiceMonitor configuration |
| prometheus.serviceMonitor.enabled | bool | `true` | Create ServiceMonitor CRD |
| prometheus.serviceMonitor.interval | string | `"30s"` | Scrape interval for eBPF events and network flows |
| prometheus.serviceMonitor.scrapeTimeout | string | `"25s"` | Scrape timeout |