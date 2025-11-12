# Quickstart

Spin up the full IDP Blueprint locally with one command, then validate access and credentials.

## Prerequisites

- Recommended: VS Code Dev Containers (repo already includes tooling), or Devbox
- Or install locally: Docker, k3d, kubectl, helm, kustomize, envsubst (gettext), dasel
- Review [Prerequisites](prerequisites.md) and ensure `docker login` to avoid rate limits
- Configure settings in `config.toml` (preferred method): LAN IP override, NodePorts, versions, passwords

## 1) Clone the repository

```bash
git clone https://github.com/rou-cru/idp-blueprint
cd idp-blueprint
```

Optional: open in VS Code and “Reopen in Container”, or run with Devbox.

!!! note
    Run `docker login` before deploying to avoid Docker Hub rate limiting during image pulls.

## 2) Deploy

```bash
task deploy
```

- Creates k3d cluster `idp-demo`
- Bootstraps Cilium, cert-manager, Vault, External Secrets, ArgoCD, Gateway
- Deploys stacks via ArgoCD ApplicationSets (observability, CI/CD, security, policies)

Time: ~5–10 minutes depending on network and hardware.

!!! tip
    The task prints the service URLs when Gateway is ready (e.g., `https://argocd.<ip>.nip.io`). Copy from the output.

!!! warning
    The Gateway uses NodePorts `30080` (HTTP) and `30443` (HTTPS). Ensure they are not in use by other services.

## 3) Access endpoints

Endpoints follow your LAN IP as a nip.io wildcard.

- ArgoCD: `https://argocd.<ip-dashed>.nip.io`
- Grafana: `https://grafana.<ip-dashed>.nip.io`
- Vault: `https://vault.<ip-dashed>.nip.io`
- Workflows: `https://workflows.<ip-dashed>.nip.io`
- SonarQube: `https://sonarqube.<ip-dashed>.nip.io`

Compute the suffix if needed:

```bash
DNS_SUFFIX="$(ip route get 1.1.1.1 | awk '{print $7; exit}' | sed 's/\./-/g').nip.io"
echo "https://argocd.$DNS_SUFFIX"
```

Accessible on your LAN: open these URLs from other devices using your
workstation IP. Ensure OS firewall allows NodePorts `30080`/`30443`.

### Quick Map

```d2
shape: sequence_diagram
User: You
Repo: GitHub (this repo)
Task: task deploy
K3d: k3d cluster
IT: IT/ bootstrap
Stacks: K8s/ stacks (AppSets)
GW: Gateway (nip.io)
UIs: ArgoCD / Grafana / Vault / Workflows / SonarQube

User -> Repo: Clone
User -> Task: Run deploy
Task -> K3d: Create cluster
Task -> IT: Cilium, cert-manager, Vault, ESO, ArgoCD, Gateway
Task -> Stacks: Observability, CI/CD, Security, Policies
User -> GW: Open https://<service>.<ip-dashed>.nip.io
GW -> UIs: Route to services
```

## 4) Credentials

ArgoCD admin password comes from Vault via External Secrets. By default it’s configured in `config.toml`:

- Username: `admin`
- Password: value of `passwords.argocd_admin` (default: `argo`)

Retrieve it from Kubernetes if you changed defaults:

```bash
kubectl -n argocd get secret argocd-secret -o jsonpath='{.data.admin\.password}' | base64 -d; echo
```

Vault is initialized automatically during deploy. Local-only root/unseal material is managed by `task vault:init` and helper scripts.

!!! note
    Prefer managing configuration via `config.toml`. Direct environment
    overrides are supported by tasks for testing, but the TOML file is the
    canonical source.

## 5) Verify

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

## 6) Clean up

Tear everything down when you’re done:

```bash
task destroy
```

## Next steps

- [First Steps](first-steps.md): Explore GitOps, policies, observability and secrets
- [Onboard an Application](../tutorials/onboard-app.md)
- [Add a Policy (Kyverno)](../tutorials/add-policy.md)
