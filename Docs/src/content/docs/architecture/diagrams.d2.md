```d2
direction: right

classes: {
  actor: {
    shape: person
    style: {
      fill: "#1e3a8a"
      stroke: "#60a5fa"
      font-color: white
    }
  }
  system: {
    style: {
      fill: "#111827"
      stroke: "#34d399"
      font-color: white
    }
  }
  ext: {
    style: {
      fill: "#0f172a"
      stroke: "#22d3ee"
      font-color: white
    }
  }
}

Platform Engineer: { class: actor }
Application Developer: { class: actor }

IDP: {
  class: system
  label: "IDP Blueprint\n(Kubernetes Cluster)"
}

Git: {
  class: ext
  label: "Git Provider"
}

Registry: {
  class: ext
  label: "Container Registry"
}

Platform Engineer -> Git: "Configures"
Application Developer -> Git: "Commits code"
Git -> IDP: "Syncs state"
Registry -> IDP: "Provides images"
IDP -> Application Developer: "Serves apps"
Platform Engineer -> IDP: "Observes"
```

```d2
direction: right

classes: {
  infra: { style: { fill: "#0f172a"; stroke: "#38bdf8"; font-color: white } }
  svc:   { style: { fill: "#0f766e"; stroke: "#34d399"; font-color: white } }
  gov:   { style: { fill: "#111827"; stroke: "#6366f1"; font-color: white } }
  ux:    { style: { fill: "#7c3aed"; stroke: "#a855f7"; font-color: white } }
}

Infra: {
  label: "Infrastructure Layer"
  K8s: { class: infra; label: "K8s API" }
  Gateway: { class: infra; label: "Gateway API" }
  Cilium: { class: infra }
}

Services: {
  label: "Platform Services"
  Vault: { class: svc }
  ESO: { class: svc; label: "External Secrets" }
  Observability: {
    class: svc
    label: "Metrics & Logs"
    tooltip: "Prometheus, Loki, Fluent-bit"
  }
}

Governance: {
  label: "Governance Layer"
  ArgoCD: { class: gov }
  Kyverno: { class: gov }
}

UX: {
  label: "Developer Portals"
  Grafana: { class: ux }
  Backstage: { class: ux }
  Workflows: { class: ux; label: "Argo Workflows" }
}

# Key Flows
Infra.Gateway -> UX: "Routes traffic"
Governance.ArgoCD -> Services: "Deploys"
Governance.ArgoCD -> UX: "Deploys"
Services.ESO -> Services.Vault: "Syncs secrets"
Governance.Kyverno -> Infra.K8s: "Enforces policy"
```
