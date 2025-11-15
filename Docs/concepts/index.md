---
# Concepts — The Mental Model of This IDP

This section explains how the main parts of the platform relate to each other so you can reason about changes and extend the IDP safely.

You won’t find step‑by‑step setup here; that lives under Getting Started and Components. Instead, this page focuses on product‑level concepts, flows, and guardrails that make the whole system coherent.

!!! note
    These concepts apply both to the demo environment in this repository and to derived deployments. Cluster size, topology, or tooling may change, but the loops and contracts described here remain the same.

## The IDP, as a Product

- A platform for developers, operated by platform engineers.
- A paved road: defaults that are secure, observable, and cost‑aware.
- One control backbone: declare in Git, reconcile to cluster, govern with policy, react to events.

## The Backbone: Desired → Observed → Actionable

The IDP runs on three feedback loops that complement each other.

```d2
direction: right

Desired: {
  label: "Desired State (Git)"
  Code: "Manifests, Values, Policies, SLOs"
}

Observed: {
  label: "Observed State"
  Metrics: "Prometheus"
  Logs: "Loki"
  SLOs: "Pyrra"
}

Actionable: {
  label: "Actionable State"
  GitOps: "ArgoCD"
  Policy: "Kyverno (enforce/audit)"
  Events: "Argo Events (planned)"
}

Desired.Code -> Actionable.GitOps: "reconcile"
Desired.Code -> Actionable.Policy: "govern"
Observed.Metrics -> Actionable.Events: "emit → trigger"
Observed.SLOs -> Actionable.Events: "burn → playbook"
Actionable.GitOps -> Observed.Metrics: "deploy → measure"
```

As you explore the docs, it can be useful to map each capability to one of these loops. If it doesn’t fit, it is either out of scope or signals that a new abstraction might be needed.

## A Guided Tour (with visuals)

### 1) Namespaces and Contracts

Each workload lives in a namespace with a contract: labels (FinOps + ownership), quotas, limits, policies. Secrets are consumed from K8s Secrets, not Vault directly.

```d2
direction: right

NS: {
  label: "Namespace = Contract"
  Labels: "owner, business-unit, environment, part-of"
  Guardrails: "Kyverno policies"
  Quotas: "LimitRange + ResourceQuota"
}

Secrets: "K8s Secret (synced by ESO)"
NS -> Secrets: "mount/consume"
```

![ArgoCD apps](../assets/images/after-deploy/argocd-apps-healthy.jpg){ loading=lazy }

### 2) Control Planes: GitOps + Policy + Events

- Git → ArgoCD reconciles Applications (ApplicationSets generate them).
- Kyverno enforces rules at admission (labels, resources, best practices).
- Argo Events (planned) turns signals (alerts, PRs, resource changes) into playbooks (workflows, syncs, HTTP calls).

```d2
direction: right

Git: {
  Repo: "Repo: idp-blueprint@HEAD"
  K8sDir: "K8s/* (stacks)"
}

Argo: {
  ApplicationSets
  Applications
}

Policy: {
  Kyverno: "validate, mutate (planned), generate (planned)"
}

Events: {
  label: "Argo Events (planned core)"
  Sources: "GitHub, Alertmanager, K8s"
  Sensors: "routes + filters"
  Triggers: "Workflows, ArgoCD, HTTP"
}

Git.Repo -> Argo.ApplicationSets: watch
Argo.ApplicationSets -> Argo.Applications: generate
Argo.Applications -> Cluster: sync
Cluster -> Policy.Kyverno: admission
Observed -> Events.Sources: signals
Events.Sensors -> Triggers: actions
```

### 3) Data Planes: Secrets, PKI, Networking, Observability

```d2
direction: right

Secrets: {
  Vault: "Source of truth"
  ESO: "sync to K8s Secrets"
}

PKI: {
  CertManager: "Root CA → Issuer → Certs"
  Wildcard: "Gateway TLS"
}

Network: {
  Cilium: "CNI + Gateway"
  GatewayAPI: "HTTPS *.nip.io"
}

Observability: {
  Prom: "Metrics"
  Loki: "Logs"
  Grafana: "Dashboards"
  Pyrra: "SLOs as code"
}
```

![Grafana](../assets/images/after-deploy/grafana-home.jpg){ loading=lazy }

### 4) What happens when you change something?

1. You commit YAML (a new chart values, a policy, or an SLO).
2. ArgoCD picks it up and syncs in order (waves), Kyverno validates.
3. Workloads run under quotas and priorities; ESO refreshes secrets as needed.
4. Prometheus/Loki report back; SLOs tick; alerts may fire; Argo Events can trigger remediation.

### 5) Safety Nets and Trade‑offs

- Integrity first: Git + ArgoCD + Kyverno keep drift in check.
- Availability is dialed by design (HA on/off per component).
- Confidentiality improves with network segmentation and mTLS (Cilium policies; planned hardening).

### 6) Extensibility Surfaces

- Add a stack folder (Kustomize/Helm) → becomes an Application automatically.
- Add policies (validate/mutate/generate) for golden paths.
- Add SLOs for critical services (Pyrra) → burn alerts → event playbooks.
- Backstage (planned) offers templates to provision apps and wire recipes.

![Cluster view](../assets/images/after-deploy/k9s-overview.jpg){ loading=lazy }

---

Next, dive into specific concepts to see each plane in context:

- [GitOps model](gitops-model.md)
- [Networking & Gateway](networking-gateway.md)
- [Secrets management](../architecture/secrets.md)
- [Scheduling & node pools](scheduling-nodepools.md)
