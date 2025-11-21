# Networking & Gateway — How traffic reaches your services

Make the networking model easy to reason about: a single Gateway receives HTTPS on `*.nip.io` and routes to internal Services. TLS is terminated at the edge; cert-manager provisions the wildcard cert.

## Big picture

```d2
direction: right

Client: {
  Browser: "User / CLI"
}

Gateway: {
  label: "Gateway API (Cilium)"
  SVC: "NodePort (nodeport_http / nodeport_https from config.toml)"
  Listener: "HTTPS *.nip.io"
  TLS: "Wildcard cert"
  Routes: {
    argocd: "argocd"
    grafana: "grafana"
    vault: "vault"
    workflows: "workflows"
    pyrra: "pyrra (SLO UI)"
  }
}

Backends: {
  argocd: "argocd-server:80"
  grafana: "prometheus-grafana:80"
  vault: "vault:8200"
  workflows: "argo-workflows-server:2746"
  pyrra: "pyrra:9099"
}

PKI: {
  CA: "idp-demo-ca"
  Issuer: "ca-issuer"
  Wildcard: "*.nip.io"
}

Client.Browser -> Gateway.SVC: HTTPS
Gateway.Listener -> PKI.Wildcard: terminate
Gateway.Routes.argocd -> Backends.argocd
Gateway.Routes.grafana -> Backends.grafana
Gateway.Routes.vault -> Backends.vault
Gateway.Routes.workflows -> Backends.workflows
Gateway.Routes.pyrra -> Backends.pyrra
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
