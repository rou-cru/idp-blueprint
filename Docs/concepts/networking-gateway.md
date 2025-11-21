# Networking & Gateway — How traffic reaches your services

Make the networking model easy to reason about: a single Gateway receives HTTPS on `*.nip.io` and routes to internal Services. TLS is terminated at the edge; cert-manager provisions the wildcard cert.

## Big picture

```d2
direction: right

classes: { actor: { style.fill: "#0f172a"; style.stroke: "#38bdf8"; style.font-color: white }
           gateway: { style.fill: "#0f172a"; style.stroke: "#22d3ee"; style.font-color: white }
           route: { style.fill: "#0f766e"; style.stroke: "#34d399"; style.font-color: white }
           backend: { style.fill: "#7c3aed"; style.stroke: "#a855f7"; style.font-color: white }
           pki: { style.fill: "#111827"; style.stroke: "#6366f1"; style.font-color: white } }

Client: { class: actor; label: "User (browser/CLI)" }

Gateway: {
  class: gateway
  label: "Gateway API (Cilium)\nNodePort http/https\nListener: HTTPS *.nip.io"
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
