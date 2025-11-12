# Verify Installation

After deploying the platform, validate core services and access endpoints.

## Quick Checks

Use these commands to confirm that control-plane and platform components are healthy:

```bash
kubectl get nodes
kubectl get pods -A
kubectl get applications -n argocd
```

!!! tip
    `k9s` is available in the Devbox/Dev Container. Run `k9s -A` for a
    curses UI to inspect pods, logs and events across namespaces.

### Visual Guide

```d2
shape: sequence_diagram
User: You
Kubectl: kubectl
Argo: ArgoCD
Gateway: Gateway
Services: UIs (argocd/grafana/vault/...)

User -> Kubectl: get nodes / pods -A
Kubectl -> Argo: get applications -n argocd
User -> Gateway: Open https://<service>.<ip-dashed>.nip.io
Gateway -> Services: Route
```

## Access Endpoints

Endpoints follow your LAN IP as a nip.io wildcard. Example if your IP is 127.0.0.1:

- ArgoCD: https://argocd.127-0-0-1.nip.io
- Grafana: https://grafana.127-0-0-1.nip.io
- Vault: https://vault.127-0-0-1.nip.io
- Argo Workflows: https://workflows.127-0-0-1.nip.io
- SonarQube: https://sonarqube.127-0-0-1.nip.io

Accessible from other devices on the same LAN using your workstation IP. Ensure
your OS firewall allows inbound NodePorts `30080` and `30443`.

## Certificate Warnings

TLS is signed by a local, self‑signed root CA for demo purposes. Browsers will
warn on first visit. You can proceed temporarily or import the CA to trust it:

```bash
# Export the root CA from cert-manager
kubectl -n cert-manager get secret idp-demo-ca-secret \
  -o jsonpath='{.data.tls\.crt}' | base64 -d > idp-demo-ca.crt
```

- macOS: open Keychain Access → System → Certificates → import `idp-demo-ca.crt` and
set “Always Trust”.
- Linux (Debian/Ubuntu): `sudo cp idp-demo-ca.crt /usr/local/share/ca-certificates/ && sudo update-ca-certificates`
- Windows: run `certmgr.msc`, import into “Trusted Root Certification Authorities”.

!!! tip
    Certificates are issued automatically by cert-manager using a wildcard
    certificate for `*.127-0-0-1.sslip.io`.

## Smoke Tests

- ArgoCD Applications show `Healthy/Synced` state
- Grafana loads and lists Prometheus and Loki data sources
- Trivy Operator reports appear under `vulnerabilityreports.aquasecurity.github.io`
- External Secrets creates Kubernetes Secrets for configured `ExternalSecret` resources

## Next

- Continue to [First Steps](first-steps.md)
- Or explore [Components](../components/infrastructure/index.md)
