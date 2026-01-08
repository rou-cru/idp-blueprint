# Networking & Connectivity Architecture (validated 2025-12-27)

## Overview
- **CNI**: Cilium (exclusive mode, kube-proxy replacement)
- **Ingress**: Gateway API (Cilium Gateway Controller)
- **Exposure**: NodePort on 30080/30443 with `*.${DNS_SUFFIX}` hostnames
- **Certificates**: cert-manager with a self-signed Root CA and wildcard cert

## Core Networking (Cilium)
Source: `IT/cilium/values.yaml`.

Key settings:
- `cni.exclusive: true` and `kubeProxyReplacement: true`
- `l7Proxy: true` and `envoy.enabled: true`
- `gatewayAPI.enabled: true`
- `ipam.mode: cluster-pool` with `clusterPoolIPv4PodCIDRList: ["10.42.0.0/16"]`
- `ipv6.enabled: false`
- `hubble.enabled: true` (Relay + UI enabled, ServiceMonitor enabled)
- Disabled for demo: `l2announcements`, `bgpControlPlane`, `encryption` (WireGuard)

## Gateway API Exposure
Sources: `IT/gateway/gatewayclass.yaml`, `IT/gateway/idp-gateway.yaml`, `IT/gateway/patch/gateway-service-patch.yaml`.

- **GatewayClass**: `cilium-nodeport` using `CiliumGatewayClassConfig` with `service.type: NodePort`.
- **Gateway**: `idp-gateway` in `kube-system` with listeners on 80/443 and hostname `*.${DNS_SUFFIX}`.
- **NodePorts**: patched service `cilium-gateway-idp-gateway` uses 30080 (HTTP) and 30443 (HTTPS).

## DNS Suffix
`Scripts/generate-env.sh` computes:
- `DNS_SUFFIX=<LAN_IP with dashes>.nip.io`

## Certificates
Sources: `IT/cert-manager/*`, `IT/gateway/idp-wildcard-cert.yaml`, `IT/gateway/gateway-tls-permission.yaml`.

- **Root CA**: `idp-demo-ca` (self-signed) in `cert-manager` namespace.
- **Issuers**: `self-signed-issuer` and `ca-issuer` (ClusterIssuers).
- **Wildcard cert**: `idp-wildcard-cert` for `*.${DNS_SUFFIX}` in `kube-system`.
- **TLS delegation**: `ReferenceGrant` allows Gateway to use the certificate across namespaces.

## HTTPRoutes
Routes are defined under `IT/gateway/httproutes/` for services like ArgoCD, Backstage, Grafana, Dex, Vault, SonarQube, Argo Events, and Argo Workflows.
