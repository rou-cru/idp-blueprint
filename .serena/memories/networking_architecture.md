# Networking & Connectivity Architecture (validated 2025-12-27)

## Overview
- **CNI**: Cilium (Exclusive mode, kube-proxy replacement).
- **Ingress**: Gateway API (v1) managed by Cilium.
- **Exposure**: NodePort strategy (mapped to host ports 30080/30443) + `nip.io` Wildcard DNS.
- **Certificates**: cert-manager + Self-Signed Root CA for local HTTPS.

## 1. Core Networking (Cilium)
- **Configuration**: `IT/cilium/values.yaml`.
- **Features**:
  - `kubeProxyReplacement: true`: Cilium handles Service load balancing via eBPF.
  - `l7Proxy: true` & `envoy: enabled`: Required for Gateway API support.
  - `gatewayAPI: enabled`: Functions as the Gateway Controller.
  - **Hubble**: Enabled with Relay + UI + Metrics (ServiceMonitor).
  - **Disabled**: L2 Announcements, BGP, Encryption (WireGuard) — kept off for k3d demo compatibility.

## 2. Connectivity & Exposure (Gateway API)
- **GatewayClass**: `cilium-nodeport` (`IT/gateway/gatewayclass.yaml`).
  - Config: `CiliumGatewayClassConfig` sets `service.type: NodePort`.
- **Gateway**: `idp-gateway` (namespace `kube-system`) listens on hostname `*.${DNS_SUFFIX}`.
- **Service**: `cilium-gateway-idp-gateway` is patched (`IT/gateway/patch/gateway-service-patch.yaml`) to enforce stable NodePorts:
  - **HTTP**: 30080
  - **HTTPS**: 30443
- **DNS**: `DNS_SUFFIX` is computed as `<LAN_IP>.nip.io` in `.env` (via `generate-env.sh`) and injected into manifests.

## 3. Certificates (cert-manager)
- **Deployment**: `cert-manager` namespace (Controller, CAInjector, Webhook).
- **Configuration**: `IT/cert-manager/values.yaml` (Prometheus metrics enabled).
- **Issuers**:
  - `self-signed-issuer`: Bootstraps the Root CA.
  - `ca-issuer`: Uses the Root CA to issue downstream certs.
- **Certificates**:
  - `idp-wildcard-cert`: Wildcard certificate for `*.${DNS_SUFFIX}` in `kube-system`.
  - **TLS Delegation**: `ReferenceGrant` (`IT/gateway/gateway-tls-permission.yaml`) allows Gateway to use this certificate across namespaces.

## 4. Application Integration
- **Routes**: `HTTPRoutes` defined in `IT/gateway/httproutes/` (and stacks) for `argocd`, `backstage`, `grafana`, `sonarqube`, etc.
- **Config Injection**: Applications like Backstage use config templates (`K8s/backstage/backstage/templates/cm-tpl.yaml`) to inject the dynamic `${DNS_SUFFIX}` at deployment time via `envsubst`.

## Production vs. Demo
- **Demo**: NodePort + `nip.io` (No external dependency).
- **Production**:
  - Change GatewayClass to LoadBalancer.
  - Enable Cilium L2 Announcements (MetalLB replacement) or BGP.
  - Use real DNS and Let's Encrypt (ACME) for certificates.
