---
title: Verify Installation — See the loops in action
sidebar:
  label: Verify Installation
  order: 5
---

Let’s confirm things came up as expected and set realistic expectations for the first minutes after deploy.

## What to expect in the first 5–10 minutes

- ArgoCD continues syncing for a bit after “task deploy” finishes
- Pods roll through Pending → Running → Ready as images download
- It’s okay if not everything is Healthy/Synced immediately

<!-- Sequence diagram removed for a simpler, first-contact explanation. -->

## Quick Checks

```bash
kubectl get nodes
kubectl get pods -A | sort
kubectl -n argocd get applications

# Optional: watch live
kubectl get pods -A -w &
kubectl -n argocd get applications -w &

# Gateway becomes ready when TLS and routes bind
kubectl -n kube-system wait --for=condition=Programmed gateway/idp-gateway --timeout=300s
```

:::tip
`k9s` ships in the Devbox/Dev Container. Try `k9s -A` and toggle between `:pods`, `:deploy`, `:events` to watch things settle.
:::

### First look at the platform

```d2
direction: right

classes: { actor: { style.fill: "#0f172a"; style.font-color: white; style.stroke: "#38bdf8" }
           gateway: { style.fill: "#0f172a"; style.stroke: "#22d3ee"; style.font-color: white }
           ui: { style.fill: "#7c3aed"; style.stroke: "#a855f7"; style.font-color: white } }

User: { class: actor; label: "You\n(Laptop)" }
Browser: { class: actor; label: "Browser" }

Gateway: { class: gateway; label: "Gateway API\nTLS *.nip.io" }

UIs: {
  class: ui
  Argo: "ArgoCD"
  Grafana
  Vault
  Backstage
}

User -> Browser: "open https://<app>.<ip>.nip.io"
Browser -> Gateway: HTTPS
Gateway -> UIs.Argo
Gateway -> UIs.Grafana
Gateway -> UIs.Vault
Gateway -> UIs.Backstage
```

## Reference screens

Below are reference screenshots to calibrate expectations right after a fresh deploy. Your exact timing may vary while images download and pods become Ready.

![k9s — pods across namespaces](../assets/images/verify/k9s-overview.jpg)

![ArgoCD — Applications appearing and converging](../assets/images/verify/argocd-apps.jpg)

![Grafana — home/dashboard with datasources wired](../assets/images/verify/grafana-home.jpg)

## Access Endpoints

Endpoints follow your LAN IP as a nip.io wildcard. If your IP is 127.0.0.1:

- ArgoCD: <https://argocd.127-0-0-1.nip.io>
- Grafana: <https://grafana.127-0-0-1.nip.io>
- Vault: <https://vault.127-0-0-1.nip.io>
- Argo Workflows: <https://workflows.127-0-0-1.nip.io>
- SonarQube: <https://sonarqube.127-0-0-1.nip.io>

Reachable from other devices on your LAN using your workstation IP. Ensure the configured NodePorts are allowed by your OS firewall.

## Login Notes

- ArgoCD admin username: `admin`
- Admin password: from Vault via ESO (defaults in `config.toml`). To read from Kubernetes:

```bash
kubectl -n argocd get secret argocd-secret -o jsonpath='{.data.admin\.password}' | base64 -d; echo
```

## Certificate Warnings

TLS uses a local, self‑signed root CA. Browsers will warn on first visit. You can proceed, or import the CA:

```bash
# Export the root CA from cert-manager
kubectl -n cert-manager get secret idp-demo-ca-secret \
  -o jsonpath='{.data.tls\.crt}' | base64 -d > idp-demo-ca.crt
```

- macOS: Keychain Access → System → Certificates → import `idp-demo-ca.crt` → “Always Trust”.
- Linux (Debian/Ubuntu): `sudo cp idp-demo-ca.crt /usr/local/share/ca-certificates/ && sudo update-ca-certificates`
- Windows: `certmgr.msc`, import into “Trusted Root Certification Authorities”.

:::tip
Certificates are issued automatically by cert-manager using a wildcard certificate for `*.127-0-0-1.nip.io`.
:::

## “Good Enough” smoke checks — eventual-consistency friendly

- [ ] ArgoCD shows Applications present; several may still be syncing, but status improves over a few minutes
- [ ] Grafana UI loads; Prometheus and Loki datasources appear after their pods are Ready
- [ ] Trivy Operator starts creating VulnerabilityReports as workloads settle
- [ ] External Secrets creates Kubernetes Secrets shortly after Vault init completes

If you prefer a checklist:

```bash
# Show Applications and their statuses
kubectl -n argocd get applications

# Confirm Prometheus targets render (when Ready)
kubectl -n observability get pods | rg prometheus | cat

# ESO synced secrets exist
kubectl get externalsecrets,secretstores -A
kubectl -n argocd get secret argocd-secret -o yaml | head -n 20
```

## Next

- Continue to [First Steps](first-steps.md)
- Or explore [Components](../components/infrastructure/index.md)
