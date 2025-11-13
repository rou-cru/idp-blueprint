# Quickstart

Spin up the full IDP Blueprint locally with one command, then validate access and credentials.

## Context at a Glance

```d2
direction: right

You: {
  label: "You"
  shape: person
}
Repo: {
  label: "GitHub Repository"
  shape: cloud
}
Cluster: {
  label: "Local IDP Cluster (k3d)"
  Gateway: {
    label: "Gateway (nip.io)"
    shape: cloud
  }
  UIs: {
    label: "UIs"
    ArgoCD: "ArgoCD"
    Grafana: "Grafana"
    Vault: "Vault"
  }
}

You -> Repo: clone
You -> Cluster.Gateway: open URLs
Cluster.Gateway -> Cluster.UIs.ArgoCD
Cluster.Gateway -> Cluster.UIs.Grafana
Cluster.Gateway -> Cluster.UIs.Vault
```

## Prerequisites

- Recommended: VS Code Dev Containers (repo already includes tooling), or Devbox
- Or install locally: Docker, k3d, kubectl, helm, kustomize, envsubst (gettext), dasel
- Review [Prerequisites](prerequisites.md) and ensure `docker login` to avoid rate limits
- Configure settings in `config.toml` (preferred method): LAN IP override, NodePorts, 
versions, passwords

## 1. Clone the repository

```bash
git clone https://github.com/rou-cru/idp-blueprint
cd idp-blueprint
```

Optional: open in VS Code and “Reopen in Container”, or run with Devbox.

!!! note
    Run `docker login` before deploying to avoid Docker Hub rate limiting during image pulls.

## 2. Deploy

```bash
task deploy
```

- Creates k3d cluster `idp-demo`
- Bootstraps Cilium, cert-manager, Vault, External Secrets, ArgoCD, Gateway
- Deploys stacks via ArgoCD ApplicationSets (observability, CI/CD, security, policies)

Time: ~5–10 minutes depending on network and hardware.

!!! tip "Heads-up: eventual consistency"
    ArgoCD will keep syncing after the task completes. It’s normal for Applications to become Healthy/Synced gradually as images download and pods become Ready.

!!! tip
    The task prints the service URLs when Gateway is ready (for example `https://argocd.<ip>.nip.io`). Copy them from the output.

!!! warning
    The Gateway uses NodePorts `30080` (HTTP) and `30443` (HTTPS).
    Ensure they are not in use by other services.

## 3. First access

When the Gateway is ready, open the printed URLs. They use a nip.io wildcard derived from your LAN IP (for example `https://argocd.192-168-1-20.nip.io`). Ensure NodePorts `30080`/`30443` are allowed by your OS firewall.

## 4. Credentials

ArgoCD admin password comes from Vault via External Secrets.
By default it’s configured in `config.toml`:

- Username: `admin`
- Password: value of `passwords.argocd_admin` (default: `argo`)

Retrieve it from Kubernetes if you changed defaults:

```bash
kubectl -n argocd get secret argocd-secret -o jsonpath='{.data.admin\.password}' | base64 -d; echo
```

Vault is initialized automatically during deploy.
Local-only root/unseal material is managed by `task vault:init` and helper scripts.

!!! note
    Prefer managing configuration via `config.toml`. Direct environment
    overrides are supported by tasks for testing, but the TOML file is the
    canonical source.

## 5. Verify

Run basic checks and confirm healthy sync:

```bash
kubectl get nodes
kubectl get pods -A
kubectl get applications -n argocd
```

See [Verify Installation](verify.md) for expected results and smoke tests.

!!! warning
    Browsers will show a warning because the demo uses a self‑signed root CA.
    You may proceed temporarily or import the CA into your OS trust store
    (see Verify Installation for steps).

## 6. Clean up

Tear everything down when you’re done:

```bash
task destroy
```

## Next steps

- [First Steps](first-steps.md): Explore GitOps, policies, observability and secrets
- [Onboard an Application](../tutorials/onboard-app.md)
- [Add a Policy (Kyverno)](../tutorials/add-policy.md)
