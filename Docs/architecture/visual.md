# Architecture visuals — key flows

This page collects a small set of diagrams that show how the main control loops and data paths work inside the platform. Use it as a visual reference after you have read:

- [Architecture overview](overview.md)
- [GitOps model](../concepts/gitops-model.md)
- [Security & policy model](../concepts/security-policy-model.md)

Each diagram focuses on a single question and links back to the relevant documentation. We keep just two cross-cutting visuals here; the rest live with their detailed pages (observability, secrets, GitOps, etc.).

## 1. Control backbone: GitOps, policy, secrets

```d2
direction: right

classes: { control: { style.fill: "#111827"; style.stroke: "#6366f1"; style.font-color: white }
           infra: { style.fill: "#0f172a"; style.stroke: "#38bdf8"; style.font-color: white }
           data: { style.fill: "#0f766e"; style.stroke: "#34d399"; style.font-color: white } }

Cluster: { class: infra; label: "Kubernetes API" }
Argo: { class: control; label: "ArgoCD + AppSets\n(GitOps reconcile)" }
Kyverno: { class: control; label: "Kyverno\n(admission + background)" }
ESO: { class: control; label: "External Secrets Operator" }
Vault: { class: data; label: "Vault (KV v2)\nsource of truth" }

Argo -> Cluster: "apply"
Kyverno <-> Cluster: "validate / mutate"
ESO -> Cluster: "create/update Secrets"
Vault -> ESO: "read secrets"
```

See: [GitOps model](../concepts/gitops-model.md), [Secrets](secrets.md), [Policies](policies.md). Colors: control (#111827/#6366f1), infra (#0f172a/#38bdf8), data (#0f766e/#34d399).

## 2. Gateway API service exposure

```d2
direction: right

classes: { gateway: { style.fill: "#0f172a"; style.stroke: "#22d3ee"; style.font-color: white }
           route: { style.fill: "#0f766e"; style.stroke: "#34d399"; style.font-color: white }
           backend: { style.fill: "#7c3aed"; style.stroke: "#a855f7"; style.font-color: white }
           actor: { style.fill: "#0f172a"; style.stroke: "#38bdf8"; style.font-color: white } }

User: { class: actor; label: "User (browser/CLI)" }

Gateway: { class: gateway; label: "Gateway API\nHTTPS TLS *.nip.io" }

Routes: {
  class: route
  Argo: "HTTPRoute: argocd"
  Grafana: "HTTPRoute: grafana"
  Vault: "HTTPRoute: vault"
  Workflows: "HTTPRoute: workflows"
  Sonar: "HTTPRoute: sonarqube"
  Backstage: "HTTPRoute: backstage"
}

Backends: {
  class: backend
  S1: "argocd-server:80"
  S2: "prometheus-grafana:80"
  S3: "vault:8200"
  S4: "argo-workflows-server:2746"
  S5: "sonarqube:9000"
  S6: "backstage:7007"
}

User -> Gateway: "HTTPS"
Gateway -> Routes.Argo
Gateway -> Routes.Grafana
Gateway -> Routes.Vault
Gateway -> Routes.Workflows
Gateway -> Routes.Sonar
Gateway -> Routes.Backstage

Routes.Argo -> Backends.S1
Routes.Grafana -> Backends.S2
Routes.Vault -> Backends.S3
Routes.Workflows -> Backends.S4
Routes.Sonar -> Backends.S5
Routes.Backstage -> Backends.S6
```

See: [Networking & gateway](../concepts/networking-gateway.md).
