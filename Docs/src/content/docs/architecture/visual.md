---
title: Visual Architecture
sidebar:
  label: Visual
  order: 9
---

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

## 3. Process Flows

These diagrams show critical platform workflows step-by-step.

### Bootstrap Complete Flow

Shows the complete platform initialization sequence from cluster creation to fully operational state.

```d2
direction: down

classes: {
  step: { style.fill: "#111827"; style.stroke: "#6366f1"; style.font-color: white }
  infra: { style.fill: "#0f172a"; style.stroke: "#38bdf8"; style.font-color: white }
  platform: { style.fill: "#0f766e"; style.stroke: "#34d399"; style.font-color: white }
  actor: { style.fill: "#1e3a8a"; style.stroke: "#60a5fa"; style.font-color: white }
}

User: {
  class: actor
  shape: person
  label: "Platform Engineer"
}

Bootstrap: {
  class: step
  label: "Bootstrap Process"

  Step1: {
    label: "1. task deploy"
    desc: "Creates k3d cluster\nInstalls Cilium CNI"
  }

  Step2: {
    label: "2. Vault Init"
    desc: "Deploys Vault\nInitializes & unseals\nCreates secrets"
  }

  Step3: {
    label: "3. External Secrets"
    desc: "Deploys ESO\nConfigures SecretStore\nSyncs first secrets"
  }

  Step4: {
    label: "4. ArgoCD"
    desc: "Deploys ArgoCD\nConfigures repo access\nCreates root Application"
  }

  Step5: {
    label: "5. ApplicationSets"
    desc: "Sync 5 ApplicationSets:\nobservability, events,\ncicd, security, backstage"
  }
}

Platform: {
  class: platform
  label: "Operational Platform"

  State: {
    label: "Platform Ready"
    Components: "All workloads running\nPolicies enforced\nMonitoring active"
  }
}

User -> Bootstrap.Step1: "task deploy"
Bootstrap.Step1 -> Bootstrap.Step2: "cluster ready"
Bootstrap.Step2 -> Bootstrap.Step3: "Vault operational"
Bootstrap.Step3 -> Bootstrap.Step4: "secrets available"
Bootstrap.Step4 -> Bootstrap.Step5: "ArgoCD syncing"
Bootstrap.Step5 -> Platform.State: "all apps healthy"
```

See: [Getting Started](../getting-started/quickstart.md) for bootstrap details.

### Secret Synchronization Flow

Shows how secrets flow from Vault to Kubernetes pods via External Secrets Operator.

```d2
direction: right

classes: {
  k8s: { style.fill: "#111827"; style.stroke: "#6366f1"; style.font-color: white }
  control: { style.fill: "#0f172a"; style.stroke: "#38bdf8"; style.font-color: white }
  data: { style.fill: "#0f766e"; style.stroke: "#34d399"; style.font-color: white }
  workload: { style.fill: "#7c3aed"; style.stroke: "#a855f7"; style.font-color: white }
}

ExternalSecret: {
  class: k8s
  label: "ExternalSecret CR"
  spec: "remoteRef:\n  key: grafana-admin"
}

ESO: {
  class: control
  label: "External Secrets Operator"
  watch: "Watches ExternalSecrets\nReconciles every 1h"
}

Vault: {
  class: data
  shape: cylinder
  label: "Vault KV v2"
  path: "secret/grafana-admin"
  link: https://www.vaultproject.io
}

K8sSecret: {
  class: k8s
  label: "Kubernetes Secret"
  data: "admin-password: <base64>"
}

Pod: {
  class: workload
  label: "Grafana Pod"
  mount: "volumeMount:\n  /etc/secrets"
}

ExternalSecret -> ESO: "triggers reconcile"
ESO -> Vault: "read secret/grafana-admin"
Vault -> ESO: "return {password: xyz}"
ESO -> K8sSecret: "create/update Secret"
K8sSecret -> Pod: "mount as volume"
```

See: [Secrets architecture](secrets.md) for detailed secret management.

### GitOps Synchronization Flow

Shows the complete flow from Git commit to running workload with policy enforcement.

```d2
direction: down

classes: {
  git: { style.fill: "#1e3a8a"; style.stroke: "#60a5fa"; style.font-color: white }
  gitops: { style.fill: "#111827"; style.stroke: "#6366f1"; style.font-color: white }
  policy: { style.fill: "#0f172a"; style.stroke: "#38bdf8"; style.font-color: white }
  k8s: { style.fill: "#0f766e"; style.stroke: "#34d399"; style.font-color: white }
  observe: { style.fill: "#7c3aed"; style.stroke: "#a855f7"; style.font-color: white }
}

GitRepo: {
  class: git
  shape: cloud
  label: "Git Repository"
  change: "K8s/observability/\nprometheus/values.yaml"
}

ArgoCD: {
  class: gitops
  label: "ArgoCD"

  Detect: {
    label: "1. Detect Change"
    method: "Polling or webhook"
  }

  Diff: {
    label: "2. Calculate Diff"
    result: "ConfigMap modified"
  }

  Sync: {
    label: "3. Apply to Cluster"
    action: "kubectl apply"
  }
}

Kyverno: {
  class: policy
  label: "Kyverno Admission"

  Validate: {
    label: "Validate Resource"
    checks: "- Has required labels?\n- Has resource limits?\n- Matches naming?"
  }

  Mutate: {
    label: "Mutate if Needed"
    actions: "- Add default labels\n- Inject sidecars"
  }
}

K8sAPI: {
  class: k8s
  label: "Kubernetes API"
  result: "Resource created/updated"
}

Prometheus: {
  class: observe
  label: "Prometheus Pod"
  state: "Reloaded with new config"
}

GitRepo -> ArgoCD.Detect: "commit pushed"
ArgoCD.Detect -> ArgoCD.Diff: "fetch manifests"
ArgoCD.Diff -> ArgoCD.Sync: "changes detected"
ArgoCD.Sync -> Kyverno.Validate: "apply request"
Kyverno.Validate -> Kyverno.Mutate: "validation passed"
Kyverno.Mutate -> K8sAPI: "mutated resource"
K8sAPI -> Prometheus: "rolling update"
```

See: [GitOps model](../concepts/gitops-model.md) and [Policy model](../concepts/security-policy-model.md).
