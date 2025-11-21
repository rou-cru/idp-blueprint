# Getting Started — Install & Deployment

This is your guided tour of what “task deploy” does. It’s automated by design and converges to a working platform in minutes.

## What Happens During Deploy

- Create cluster and namespaces
- Install core infrastructure (Cilium, CRDs, cert-manager, Vault, ESO)
- Install GitOps (ArgoCD) and expose endpoints via Gateway + TLS
- Apply policies and let ApplicationSets sync the stacks – ApplicationSets
  generate the ArgoCD Applications for each stack based on folders under
  `K8s/` using sync waves to control deployment order (see [GitOps Model](../concepts/gitops-model.md#sync-waves--ordering-without-scripts) for wave definitions)

### Platform Components

```d2
direction: right

classes: { step: { style.fill: "#0f172a"; style.font-color: white; style.stroke: "#22d3ee" } }

Bootstrap: {
  class: step
  K3d: "Create k3d cluster"
  Core: "Install core (Cilium, cert-manager, Vault, ESO)"
  Argo: "Install ArgoCD + AppProjects"
  Gateway: "Apply Gateway API + wildcard cert"
  Policies: "Deploy Kyverno + Policy Reporter"
}

GitOps: {
  class: step
  Stacks: "Sync stacks (observability, CI/CD, security, backstage)"
  Govern: "Enforce quotas/limits/labels"
}

Bootstrap.K3d -> Bootstrap.Core -> Bootstrap.Argo -> Bootstrap.Gateway -> Bootstrap.Policies -> GitOps.Stacks -> GitOps.Govern
```

## Configure via config.toml

Prefer editing `config.toml` in the repo root; tasks read all settings from there. Example:

```toml
[network]
lan_ip = "192.168.1.20"   # override auto-detected IP
# HTTP/HTTPS NodePorts used by the Gateway (k3d config and Service patch consume these)
nodeport_http = 30080
nodeport_https = 30443

[git]
repo_url = "https://github.com/rou-cru/idp-blueprint"
target_revision = "main"

[versions]
cilium = "1.18.2"
cert_manager = "1.19.0"
vault = "0.31.0"

[passwords]
argocd_admin = "argo"
grafana_admin = "admin"
```

Note: CLI overrides exist for testing, but `config.toml` is the canonical source.

## After deploy — what “good” looks like

- ArgoCD UI reachable via Gateway (nip.io hostnames)
  
  ![ArgoCD Applications — expected convergence to Healthy/Synced](../assets/images/after-deploy/argocd-apps-healthy.jpg)

- Core pods ready across namespaces (k9s view)
  
  ![k9s — pods across namespaces settling after deploy](../assets/images/after-deploy/k9s-overview.jpg)

- Observability online (Grafana with Prometheus and Loki datasources)
  
  ![Grafana — home with Prometheus/Loki datasources available](../assets/images/after-deploy/grafana-home.jpg)

<!-- Troubleshooting intentionally omitted in this page to avoid redundancy. Use the dedicated reference when needed. -->
