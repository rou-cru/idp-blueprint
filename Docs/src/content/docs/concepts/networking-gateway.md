---
title: Networking & Gateway
sidebar:
  label: Networking & Gateway
  order: 4
---

Make the networking model easy to reason about: a single Gateway receives HTTPS on `*.nip.io` and routes to internal Services. TLS is terminated at the edge; cert-manager provisions the wildcard cert.

## Big picture

```d2
direction: right

classes: { actor: { style.fill: "#0f172a"; style.stroke: "#38bdf8"; style.font-color: white }
           gateway: { style.fill: "#0f172a"; style.stroke: "#22d3ee"; style.font-color: white }
           route: { style.fill: "#0f766e"; style.stroke: "#34d399"; style.font-color: white }
           backend: { style.fill: "#7c3aed"; style.stroke: "#a855f7"; style.font-color: white }
           pki: { style.fill: "#111827"; style.stroke: "#6366f1"; style.font-color: white } }

Client: {
  class: actor
  shape: person
  label: "User (browser/CLI)"
}

Gateway: {
  class: gateway
  shape: hexagon
  label: "Gateway API (Cilium)\nNodePort http/https\nListener: HTTPS *.nip.io"
  link: https://gateway-api.sigs.k8s.io
}

Routes: {
  class: route
  Argo: "argocd"
  Grafana: "grafana"
  Vault: "vault"
  Workflows: "workflows"
  Pyrra: "pyrra"
  Backstage: "backstage"
}

Backends: {
  class: backend
  A: "argocd-server:80"
  G: "prometheus-grafana:80"
  V: "vault:8200"
  W: "argo-workflows-server:2746"
  P: "pyrra:9099"
  B: "backstage:7007"
}

PKI: { class: pki; label: "PKI\nCA: idp-demo-ca\nIssuer: ca-issuer\nWildcard: *.nip.io" }

Client -> Gateway: HTTPS
Gateway -> Routes.Argo
Gateway -> Routes.Grafana
Gateway -> Routes.Vault
Gateway -> Routes.Workflows
Gateway -> Routes.Pyrra
Gateway -> Routes.Backstage

Routes.Argo -> Backends.A
Routes.Grafana -> Backends.G
Routes.Vault -> Backends.V
Routes.Workflows -> Backends.W
Routes.Pyrra -> Backends.P
Routes.Backstage -> Backends.B

PKI -> Gateway: "TLS termination"
```

## Detailed Networking Architecture (C3)

This diagram shows the complete network path from external clients through Cilium CNI to backend pods.

```d2
direction: down

classes: {
  external: { style.fill: "#1e3a8a"; style.stroke: "#60a5fa"; style.font-color: white }
  infra: { style.fill: "#0f172a"; style.stroke: "#38bdf8"; style.font-color: white }
  control: { style.fill: "#111827"; style.stroke: "#6366f1"; style.font-color: white }
  data: { style.fill: "#0f766e"; style.stroke: "#34d399"; style.font-color: white }
  app: { style.fill: "#7c3aed"; style.stroke: "#a855f7"; style.font-color: white }
}

Client: {
  class: external
  shape: person
  label: "External Client"
}

L3L4: {
  class: infra
  label: "L3/L4 - Node & CNI"
  Node: {
    label: "Kubernetes Node\neth0: LAN IP"
  }
  Cilium: {
    label: "Cilium CNI\neBPF datapath"
    link: https://cilium.io
    tooltip: |md
      eBPF-based CNI providing:
      - Pod networking
      - Service load balancing
      - NetworkPolicy enforcement
    |
  }
  NodePort: {
    label: "NodePort Service\n30080 (HTTP)\n30443 (HTTPS)"
  }
}

L7: {
  class: control
  label: "L7 - Gateway API"

  GatewayClass: {
    label: "GatewayClass\ncilium-nodeport"
  }

  Gateway: {
    shape: hexagon
    label: "Gateway: idp-gateway\nListener HTTPS *.nip.io"
  }

  HTTPRoutes: {
    label: "HTTPRoutes (per service)"
    Argo: "argocd.*.nip.io"
    Grafana: "grafana.*.nip.io"
    Vault: "vault.*.nip.io"
  }
}

TLS: {
  class: control
  label: "TLS & Certificates"

  CertManager: {
    label: "cert-manager"
    link: https://cert-manager.io
  }

  CA: {
    label: "ClusterIssuer: ca-issuer\nCA: idp-demo-ca"
    shape: cylinder
  }

  WildcardCert: {
    label: "Certificate\n*.nip.io"
  }
}

Services: {
  class: data
  label: "Kubernetes Services (ClusterIP)"

  ArgoSvc: "argocd-server:80"
  GrafanaSvc: "prometheus-grafana:80"
  VaultSvc: "vault:8200"
}

Pods: {
  class: app
  label: "Backend Pods"

  ArgoPod: "argocd-server-*"
  GrafanaPod: "prometheus-grafana-*"
  VaultPod: "vault-0"
}

Client -> L3L4.Node: "HTTPS :30443"
L3L4.Node -> L3L4.NodePort: "forward"
L3L4.NodePort -> L3L4.Cilium: "route to Gateway"
L3L4.Cilium -> L7.Gateway: "service mesh"

L7.GatewayClass -> L7.Gateway: "implements"
L7.Gateway -> L7.HTTPRoutes.Argo: "TLS termination\nroute by hostname"
L7.Gateway -> L7.HTTPRoutes.Grafana
L7.Gateway -> L7.HTTPRoutes.Vault

L7.HTTPRoutes.Argo -> Services.ArgoSvc: "backend ref"
L7.HTTPRoutes.Grafana -> Services.GrafanaSvc
L7.HTTPRoutes.Vault -> Services.VaultSvc

Services.ArgoSvc -> Pods.ArgoPod: "endpoint"
Services.GrafanaSvc -> Pods.GrafanaPod
Services.VaultSvc -> Pods.VaultPod

TLS.CertManager -> TLS.CA: "uses"
TLS.CA -> TLS.WildcardCert: "issues"
TLS.WildcardCert -> L7.Gateway: "mounts as Secret"
```

### Network Flow Explanation

1. **L3/L4 Layer (Node & CNI)**:
   - External client connects to NodePort (30443) on any cluster node
   - Cilium CNI handles pod networking using eBPF datapath
   - NodePort Service forwards traffic to Gateway implementation

2. **L7 Layer (Gateway API)**:
   - `GatewayClass` defines how Gateways are implemented (cilium-nodeport)
   - `Gateway` resource creates HTTPS listener on *.nip.io with TLS termination
   - `HTTPRoute` resources define hostname-based routing to backend Services

3. **TLS/PKI Layer**:
   - cert-manager automates certificate lifecycle
   - ClusterIssuer uses internal CA (idp-demo-ca)
   - Wildcard certificate (*.nip.io) is issued and mounted into Gateway

4. **Backend Layer**:
   - Services provide stable ClusterIP endpoints
   - Cilium load balances across pod endpoints
   - Pods serve actual application traffic

### NetworkPolicies (Future)

Cilium supports NetworkPolicies for L3/L4 and L7 network segmentation. This platform has Cilium configured but NetworkPolicies are not yet implemented.

**Planned NetworkPolicy strategy**:
- Default-deny in production namespaces
- Explicit allow rules for required communication
- L7 policies for HTTP-specific controls (e.g., only allow GET/POST)

See [Security & Policy Model](security-policy-model.md#layer-1-network-security) for the security roadmap.

## Decision: Gateway API over Ingress

The platform uses **Gateway API**, not traditional Ingress resources, for a few
reasons:

- **Clear separation of concerns** – `Gateway` objects capture infrastructure
  concerns (listeners, TLS, IPs), while `HTTPRoute` objects live closer to
  applications and can be owned by teams.
- **More expressive routing** – header matching, weighted traffic, and
  cross‑namespace routing are first‑class in Gateway API instead of relying on
  vendor‑specific Ingress annotations.
- **Cilium integration** – Cilium ships a native Gateway API implementation, so
  we do not need an additional ingress controller.
- **Future‑proofing** – Gateway API is the direction the Kubernetes ecosystem
  is converging on for service exposure.

For low‑level details and configuration knobs, see the
[`Gateway API` component documentation](../components/infrastructure/gateway-api/index.md).

## What to remember

- The Gateway is the only public entry point.
- Host‑based routes keep URLs predictable: `https://argocd.${DNS_SUFFIX}`.
- TLS is internal, too: prefer mTLS inside the mesh (planned with Cilium policies).

![Grafana](../assets/images/after-deploy/grafana-home.jpg){ loading=lazy }

## Practical notes

- `GatewayClass: cilium-nodeport` and a single `Gateway: idp-gateway` live in `kube-system`.
- DNS suffix is computed automatically from your LAN IP; override via `config.toml` if needed.
- Add new services with an `HTTPRoute` per hostname.
