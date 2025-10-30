# cilium

This document lists the configuration parameters for the `cilium` component.

## Values

### Kube-proxy Replacement

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kubeProxyReplacement | bool | `true` | Replace kube-proxy with Cilium's eBPF implementation |

### Network Policy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| policyEnforcementMode | string | `"default"` | Default enforcement mode for CiliumNetworkPolicy |

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
| hubble.metrics.enabled | list | `["dns:query;ignoreAAAA","drop","tcp","flow","port-distribution","icmp","http"]` | Enabled metrics for Hubble to collect |
| hubble.relay.enabled | bool | `true` | Enable Hubble Relay |
| hubble.relay.replicas | int | `1` | Number of replicas |
| hubble.relay.resources.limits.cpu | string | `"500m"` | CPU limit |
| hubble.relay.resources.limits.memory | string | `"256Mi"` | Memory limit |
| hubble.relay.resources.requests.cpu | string | `"100m"` | CPU request |
| hubble.relay.resources.requests.memory | string | `"128Mi"` | Memory request |
| hubble.ui.enabled | bool | `true` | Enable Hubble UI |
| hubble.ui.ingress.enabled | bool | `false` | Enable ingress |
| hubble.ui.replicas | int | `1` | Number of replicas |
| hubble.ui.resources.limits.cpu | string | `"100m"` | CPU limit |
| hubble.ui.resources.limits.memory | string | `"128Mi"` | Memory limit |
| hubble.ui.resources.requests.cpu | string | `"50m"` | CPU request |
| hubble.ui.resources.requests.memory | string | `"64Mi"` | Memory request |
| hubble.ui.service.type | string | `"ClusterIP"` | Service type |
| ingressController.default | bool | `true` | Make this the default IngressClass |
| ingressController.enabled | bool | `true` | Enable the Ingress Controller |
| ingressController.loadbalancerMode | string | `"shared"` | Use shared service for all Ingresses |
| ingressController.service.type | string | `"LoadBalancer"` | Service type (k3d load balancer will handle this) |
| ipam.mode | string | `"cluster-pool"` | IPAM mode (cluster-pool recommended for efficient allocation) |
| ipam.operator.clusterPoolIPv4PodCIDRList | list | `["10.42.0.0/16"]` | Pod CIDR for the cluster (must match k3d default) |
| ipv6.enabled | bool | `false` | Enable IPv6 support (disabled for demo performance) |
| operator.prometheus.enabled | bool | `true` | Enable Prometheus metrics |
| operator.prometheus.serviceMonitor.enabled | bool | `true` | Enable ServiceMonitor |
| operator.prometheus.serviceMonitor.interval | string | `"30s"` | Scrape interval for critical CNI metrics |
| operator.prometheus.serviceMonitor.scrapeTimeout | string | `"25s"` | Scrape timeout |
| operator.replicas | int | `1` | Number of replicas for the operator |
| operator.resources.limits.cpu | string | `"500m"` | CPU limit |
| operator.resources.limits.memory | string | `"512Mi"` | Memory limit |
| operator.resources.requests.cpu | string | `"100m"` | CPU request |
| operator.resources.requests.memory | string | `"128Mi"` | Memory request |
| prometheus.dashboards.enabled | bool | `true` | Create ConfigMap with official Cilium dashboard |
| prometheus.dashboards.namespace | string | `"default"` | Namespace for dashboard ConfigMap |
| prometheus.enabled | bool | `true` | Enable metrics exposition |
| prometheus.serviceMonitor.enabled | bool | `true` | Create ServiceMonitor CRD |
| prometheus.serviceMonitor.interval | string | `"30s"` | Scrape interval for eBPF events and network flows |
| prometheus.serviceMonitor.scrapeTimeout | string | `"25s"` | Scrape timeout |