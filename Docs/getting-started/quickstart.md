# Quickstart

Spin up the full IDP Blueprint locally with one command, then validate access and credentials.

## Prerequisites

- Recommended: VS Code Dev Containers (repo already includes tooling), or Devbox
- Or install locally: Docker, k3d, kubectl, helm, kustomize, envsubst (gettext), dasel
- Review [Prerequisites](prerequisites.md) and ensure `docker login` to avoid rate limits

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

## 4) Credentials

ArgoCD admin password comes from Vault via External Secrets. By default it’s configured in `config.toml`:

- Username: `admin`
- Password: value of `passwords.argocd_admin` (default: `argo`)

Retrieve it from Kubernetes if you changed defaults:

```bash
kubectl -n argocd get secret argocd-secret -o jsonpath='{.data.admin\.password}' | base64 -d; echo
```

Vault is initialized automatically during deploy. Local-only root/unseal material is managed by `task vault:init` and helper scripts.

## 5) Verify

Run basic checks and confirm healthy sync:

```bash
kubectl get nodes
kubectl get pods -A
kubectl get applications -n argocd
```

See [Verify Installation](verify.md) for expected results and smoke tests.

## 6) Clean up

Tear everything down when you’re done:

```bash
task destroy
```

## Next steps

- [First Steps](first-steps.md): Explore GitOps, policies, observability and secrets
- [Onboard an Application](../tutorials/onboard-app.md)
- [Add a Policy (Kyverno)](../tutorials/add-policy.md)
