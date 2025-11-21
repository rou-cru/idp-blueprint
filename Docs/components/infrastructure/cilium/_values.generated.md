# cilium

![Version: 1.18.2](https://img.shields.io/badge/Version-1.18.2-informational?style=flat-square)

## Component Information

| Property | Value |
|----------|-------|
| **Chart Version** | `1.18.2` |
| **Chart Type** | `` |
| **Upstream Project** | N/A |

## Configuration Values

The following table lists the configurable parameters:

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
| bpf.hostRouting | bool | `false` | Enable BPF host routing for improved performance Disabled for k3d/Docker environments - causes DNS resolution issues Enable only for bare-metal/VM deployments |
| bpf.masquerade | bool | `false` | Enable BPF masquerading for traffic leaving cluster nodes Disabled for k3d/Docker environments - interferes with Docker bridge networking and causes DNS responses to be malformed ("server misbehaving" errors) Enable only for bare-metal/VM deployments |
| bpf.monitorAggregation | string | `"medium"` | Monitor aggregation level |
| bpf.monitorFlags | string | `"all"` | Monitor flags |
| bpf.monitorInterval | string | `"10s"` | Monitor interval |
| cluster.id | int | `1` | Cluster ID |
| cluster.name | string | `"idp-demo"` | Cluster name |
| cni.chainingMode | string | `"none"` | CNI chaining mode (none = complete CNI replacement) |
| cni.exclusive | bool | `true` | Exclusive mode (Cilium is the only CNI) |
| commonLabels."app.kubernetes.io/component" | string | `"cni"` | Application component |
| commonLabels."app.kubernetes.io/instance" | string | `"cilium-demo"` | Application instance |
| commonLabels."app.kubernetes.io/part-of" | string | `"idp"` | Part of platform |
| commonLabels."app.kubernetes.io/version" | string | `"1.18.2"` | Application version |
| commonLabels.business-unit | string | `"infrastructure"` | Business unit |
| commonLabels.environment | string | `"demo"` | Environment |
| commonLabels.owner | string | `"platform-team"` | Owner |
| enableK8sEndpointSlice | bool | `true` | Enable Kubernetes EndpointSlice feature |
| encryption.enabled | bool | `false` | Enable encryption (disabled for local demo) |
| encryption.type | string | `"wireguard"` | Encryption type |
| envoy.enabled | bool | `true` | Enable Envoy proxy |
| envoy.prometheus.enabled | bool | `true` |  |
| envoy.prometheus.serviceMonitor.enabled | bool | `true` |  |
| externalIPs.enabled | bool | `false` | Enable external IPs |
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
| ingressController.enabled | bool | `false` | Enable the Ingress Controller |
| ipam.mode | string | `"cluster-pool"` | IPAM mode (cluster-pool recommended for efficient allocation) |
| ipam.operator.clusterPoolIPv4PodCIDRList | list | `["10.42.0.0/16"]` | Pod CIDR for the cluster (must match k3d default) |
| ipv6.enabled | bool | `false` | Enable IPv6 support (disabled for demo performance) |
| l2announcements.enabled | bool | `false` | Enable L2 announcements |
| l2announcements.leaseDuration | string | `"3s"` | Lease duration |
| l2announcements.leaseRenewDeadline | string | `"1s"` | Lease renew deadline |
| l2announcements.leaseRetryPeriod | string | `"500ms"` | Lease retry period |
| l7Proxy | bool | `true` |  |
| operator.priorityClassName | string | `"platform-infrastructure"` | Priority class for the Cilium operator |
| operator.prometheus.enabled | bool | `true` | Enable Prometheus metrics |
| operator.prometheus.serviceMonitor.enabled | bool | `true` | Enable ServiceMonitor |
| operator.prometheus.serviceMonitor.interval | string | `"30s"` | Scrape interval for critical CNI metrics |
| operator.prometheus.serviceMonitor.scrapeTimeout | string | `"25s"` | Scrape timeout |
| operator.replicas | int | `1` | Number of replicas for the operator |
| operator.resources.limits.cpu | string | `"500m"` | CPU limit |
| operator.resources.limits.memory | string | `"512Mi"` | Memory limit |
| operator.resources.requests.cpu | string | `"100m"` | CPU request |
| operator.resources.requests.memory | string | `"128Mi"` | Memory request |
| operator.updateStrategy | object | `{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0},"type":"RollingUpdate"}` | Rolling update strategy for zero-downtime updates |
| operator.updateStrategy.rollingUpdate.maxSurge | int | `1` | Maximum surge pods during update |
| operator.updateStrategy.rollingUpdate.maxUnavailable | int | `0` | Maximum unavailable pods during update (0 for zero-downtime) |
| prometheus.dashboards.enabled | bool | `true` | Create ConfigMap with official Cilium dashboard |
| prometheus.dashboards.namespace | string | `"default"` | Namespace for dashboard ConfigMap |
| prometheus.enabled | bool | `true` | Enable metrics exposition |
| prometheus.serviceMonitor.enabled | bool | `true` | Create ServiceMonitor CRD |
| prometheus.serviceMonitor.interval | string | `"30s"` | Scrape interval for eBPF events and network flows |
| prometheus.serviceMonitor.scrapeTimeout | string | `"25s"` | Scrape timeout |
