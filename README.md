IDP Blueprint
=============

Open-source reference for a compact Internal Developer Platform that runs on a local or lab Kubernetes cluster (k3d by default). It ships GitOps, policy, observability, CI/CD, and secrets management as code, deployable with one command.

What you get
------------

- GitOps backbone: ArgoCD + ApplicationSets (app-of-appsets pattern).
- Policy and governance: Kyverno + Policy Reporter.
- Networking and ingress: Cilium CNI, Gateway API with wildcard TLS.
- Secrets: Vault + External Secrets Operator.
- Observability: Prometheus Operator CRDs, Grafana, Loki, Fluent Bit, Pyrra.
- CI/CD: Argo Workflows, SonarQube.
- Developer portal: Backstage.

One-command deploy
------------------

Default settings (from `config.toml`) install everything on k3d with a single CLI call. The Taskfile coordinates the sequence below; ArgoCD keeps reconciling after the command returns.

```
task deploy
```

What actually happens (high level):

1) Create k3d cluster `idp-demo`, registry cache, namespaces, priority classes.
2) Install CRDs (Gateway API, Prometheus Operator) and Cilium CNI.
3) Install cert-manager, then Vault; initialize/unseal Vault and seed platform secrets.
4) Install External Secrets Operator.
5) Install ArgoCD and AppProjects; apply ExternalSecret for ArgoCD admin.
6) Deploy Gateway (NodePorts 30080/30443, nip.io wildcard) and print service URLs.
7) Apply Kyverno/Policy Reporter Application; apply ApplicationSets for observability, cicd, security, backstage, and events (events always on; other stacks gated by fuses in `config.toml`).

Requirements (local demo)
-------------------------

- Docker engine capable of running k3d.
- Recommended: VS Code Dev Container or Devbox (toolchain auto-provisioned from `devbox.json`).
- Warning (solo si no usas el entorno autocontenido): instala Task, k3d, kubectl, helm, kustomize, envsubst (gettext) y dasel en tu host.
- Baseline resources: 4 vCPU / 8 GiB RAM minimum; 6 vCPU / 12 GiB RAM is comfortable. ~20 GiB disk free.

Configuration
-------------

- `config.toml` is the single source for versions, NodePorts, passwords, fuses (stack toggles), and repo/branch overrides.
- Feature toggles (`[fuses]`): `policies`, `observability`, `cicd`, `security`, `backstage`, `prod` (enables HA for ArgoCD today).
- NodePorts default to HTTP 30080 / HTTPS 30443; service hostnames use `<service>.<lan-ip-dashed>.nip.io`.

Repository layout
-----------------

- `IT/` – bootstrap layer (Cilium, cert-manager, Vault, ESO, ArgoCD, Gateway, namespaces, priority classes).
- `K8s/` – GitOps application stacks; ApplicationSets discover subdirectories.
- `Policies/` – Kyverno engine and policies (standalone ArgoCD Application).
- `Taskfile.yaml` and `Task/` – orchestration entrypoints and includes.
- `Scripts/` – helpers for config extraction, vault init/seed, helm-docs, validation.
- `Docs/` – Astro/Starlight documentation site (authoring source).
- `config.toml` – user-facing configuration defaults.

Common tasks
------------

- `task deploy`       – full bootstrap + stacks (respecting fuses, events always on).
- `task destroy`      – delete k3d cluster and registry cache.
- `task stacks:deploy`– reapply stacks only (GitOps layer).
- `task quality:check`– lint + validate + security scans.
- `task utils:config:print` – show effective repo/branch, cluster name, NodePorts, fuses.

Documentation
-------------

- Source lives in `Docs/` (Astro/Starlight). Run `task docs:astro:build` to build, or `task docs:astro:dev` to serve locally.

Contributing
------------

PRs and issues are welcome: policy additions, resource tuning, docs improvements, integrations. See `CONTRIBUTING.md` for guidelines.

License
-------

MIT
