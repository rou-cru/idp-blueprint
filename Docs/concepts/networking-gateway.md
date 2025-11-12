# Networking & Gateway

Inbound traffic is handled via Gateway API on top of Cilium’s Gateway Controller. For local setups, services are exposed through a NodePort Gateway and reachable under wildcard nip.io domains derived from your LAN IP.

## Overview

- GatewayClass: `cilium-nodeport` (NodePort‑backed Gateway)
- Gateway: `kube-system/idp-gateway`, TLS termination with a wildcard cert
- HTTPRoutes: one route per service (ArgoCD, Grafana, Vault, Workflows, SonarQube)
- DNS: `*.<ip-dashed>.nip.io` generated from your detected LAN IP or `network.lan_ip` in `config.toml`

See the [Gateway API diagram](../architecture/visual.md#8-gateway-api-service-exposure) for a visual flow.

## Prerequisites (installed by bootstrap tasks)

- Gateway API CRDs installed (`bootstrap:it:apply-gateway-api-crds`)
- Cilium with Gateway API enabled (see `IT/cilium/cilium-values.yaml` → `gatewayAPI.enabled: true`)
- cert-manager with a root CA and issuers (`IT/cert-manager/*`)

## GatewayClass and Gateway

`IT/gateway/gatewayclass.yaml` defines a NodePort GatewayClass and its Cilium parameters:

```yaml
apiVersion: cilium.io/v2alpha1
kind: CiliumGatewayClassConfig
spec:
  service:
    type: NodePort
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: cilium-nodeport
spec:
  controllerName: io.cilium/gateway-controller
```

`IT/gateway/idp-gateway.yaml` declares the main Gateway with TLS terminated on a wildcard certificate:

```yaml
spec:
  gatewayClassName: cilium-nodeport
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      hostname: "*.${DNS_SUFFIX}"
      tls:
        mode: Terminate
        certificateRefs:
          - name: idp-wildcard-cert
```

## TLS Certificates

cert-manager bootstraps a self‑signed root CA, then a ClusterIssuer uses it to sign the wildcard certificate:

- Root CA: `IT/cert-manager/idp-demo-ca.yaml` (issued by `self-signed-issuer`)
- ClusterIssuer: `IT/cert-manager/ca-issuer.yaml` (reads `idp-demo-ca-secret`)
- Wildcard cert: `IT/gateway/idp-wildcard-cert.yaml` (secret `idp-wildcard-cert`)

With Cilium, Envoy needs explicit permission to read the TLS Secret:

- `IT/gateway/gateway-tls-permission.yaml` (CiliumClusterwideEnvoyConfig → Secret access)

## Gateway Flow (Diagram)

=== "D2"

```d2
direction: down

External: {
  Browser
}

KubeSystem: {
  label: "Namespace: kube-system"
  SVC: "Service: cilium-gateway-idp-gateway\nNodePort 30080/30443"
  GW: "Gateway: idp-gateway\nTLS terminate"
}

Routes: {
  label: "HTTPRoutes"
  HR1: argocd
  HR2: grafana
  HR3: vault
  HR4: workflows
  HR5: sonarqube
}

Backends: {
  label: "Backend Services"
  S1: "argocd-server:80"
  S2: "prometheus-grafana:80"
  S3: "vault:8200"
  S4: "argo-workflows-server:2746"
  S5: "sonarqube:9000"
}

Certificates: {
  label: "cert-manager"
  SSI: "ClusterIssuer: self-signed"
  CA: "Certificate: idp-demo-ca\nsecret idp-demo-ca-secret"
  ISS: "ClusterIssuer: ca-issuer"
  CERT: "Certificate: idp-wildcard-cert\nsecret idp-wildcard-cert"
}

External.Browser -> KubeSystem.SVC: "HTTPS nip.io"
KubeSystem.SVC -> KubeSystem.GW
KubeSystem.GW -> Routes.HR1: "hostname match"
KubeSystem.GW -> Routes.HR2
KubeSystem.GW -> Routes.HR3
KubeSystem.GW -> Routes.HR4
KubeSystem.GW -> Routes.HR5
Routes.HR1 -> Backends.S1
Routes.HR2 -> Backends.S2
Routes.HR3 -> Backends.S3
Routes.HR4 -> Backends.S4
Routes.HR5 -> Backends.S5
KubeSystem.GW -> Certificates.CERT: "uses TLS"
Certificates.CERT <- Certificates.ISS <- Certificates.CA <- Certificates.SSI
```


## DNS Suffix and Domains

The `gateway:deploy` task computes `DNS_SUFFIX` from your LAN IP:

```bash
DNS_SUFFIX="$(ip route get 1.1.1.1 | awk '{print $7; exit}' | sed 's/\./-/g').nip.io"
```

Override the detected IP via `config.toml` → `network.lan_ip`. Hostnames follow the pattern:

- ArgoCD: `https://argocd.${DNS_SUFFIX}`
- Grafana: `https://grafana.${DNS_SUFFIX}`
- Vault: `https://vault.${DNS_SUFFIX}`
- Workflows: `https://workflows.${DNS_SUFFIX}`
- SonarQube: `https://sonarqube.${DNS_SUFFIX}`

## Routes

HTTPRoutes map each hostname to its backend Service. Example (`IT/gateway/httproutes/argocd-httproute.yaml`):

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
spec:
  parentRefs:
    - name: idp-gateway
      namespace: kube-system
  hostnames:
    - "argocd.${DNS_SUFFIX}"
  rules:
    - backendRefs:
        - name: argocd-server
          port: 80
```

Add more services by creating additional `HTTPRoute` resources with the desired hostname and backend.

## LAN Access

Because the Gateway Service is `NodePort`, services are reachable from other
devices on your network using the host’s LAN IP (nip.io wildcard). Open the
required ports in your OS firewall if needed: HTTP `30080`, HTTPS `30443`.

## Certificates & Browser Trust

Demo TLS uses a locally generated root CA via cert‑manager. Expect browser
warnings. To trust locally, export the CA and add it to your OS trust store
(see Verify Installation for commands). For production, replace with an
enterprise CA or ACME issuer.

## NodePorts and Verification

The NodePort Service for the Gateway is patched and verified during deployment:

- Expected NodePorts (defaults): HTTP `30080`, HTTPS `30443` (from `config.toml`)
- Patch: `IT/gateway/patch/gateway-service-patch.yaml`

The task checks readiness and prints URLs:

```bash
kubectl wait --for=condition=Programmed gateway/idp-gateway -n kube-system --timeout=300s
```

Troubleshooting commands:

```bash
kubectl get gatewayclasses
kubectl get gateway -n kube-system idp-gateway -o yaml | head -n 50
kubectl get httproute -A
kubectl get svc cilium-gateway-idp-gateway -n kube-system -o wide
```

## Reference

- Ports & Endpoints: [reference/ports-endpoints.md](../reference/ports-endpoints.md)
- Verify Installation: [getting-started/verify.md](../getting-started/verify.md)
- Cilium values: `IT/cilium/cilium-values.yaml`
- Gateway manifests: `IT/gateway/*`
