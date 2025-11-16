# Architecture visuals — key flows

This page collects a small set of diagrams that show how the main control loops and data paths work inside the platform. Use it as a visual reference after you have read:

- [Architecture overview](overview.md)
- [GitOps model](../concepts/gitops-model.md)
- [Security & policy model](../concepts/security-policy-model.md)

Each diagram focuses on a single question and links back to the relevant documentation. Think of these as **cross-cutting slices across the C4 views** from the Architecture section (they mix context, containers, and components to answer one concrete question).

## 1. Control backbone: GitOps, policy, and secrets

**Question:** how do GitOps, admission policy, and secrets reconciliation interact?

```d2
direction: right

K8s: "Kubernetes API Server"
GitOps: {
  Argo: ArgoCD
}
Policy: {
  Kyverno
}
Secrets: {
  ESO: "External Secrets Operator"
}

GitOps.Argo <-> K8s: "Reconciles Git state"
Policy.Kyverno <-> K8s: "Validates & mutates"
Secrets.ESO <-> K8s: "Syncs secrets"
```

- ArgoCD reconciles manifests from Git into the cluster.
- Kyverno validates and optionally mutates or generates resources at admission.
- ESO keeps Kubernetes Secrets in sync with Vault and other secret stores.

See:
- [GitOps model](../concepts/gitops-model.md)
- [Security & policy model](../concepts/security-policy-model.md)
- [Secrets management architecture](secrets.md)

## 2. Secret management flow

**Question:** how does an application pod receive a secret from Vault?

```d2
direction: right

Vault: {
  label: "Vault\n(KV secrets)"
}

ESO: {
  label: "External Secrets Operator"
}

K8S: {
  label: "Kubernetes Secret\n(target)"
}

App: {
  label: "Application pod"
}

ES: {
  label: "ExternalSecret CR\n(desired secret + path)"
}

SS: {
  label: "ClusterSecretStore\n(auth & backend config)"
}

Vault -> ESO: "read secret data"
ESO -> K8S: "create / update Secret"
K8S -> App: "mount as env / volume"

ES -> ESO: "spec: secretStoreRef, dataFrom..."
SS -> ESO: "Vault address, auth, paths"
```

See:
- [Secrets management architecture](secrets.md)
- [Security & policy model](../concepts/security-policy-model.md)

## 3. Observability data flow

**Question:** how do metrics and logs move from nodes to dashboards?

```d2
direction: right

Nodes: {
  App: "App pod"
  Kubelet
  NodeExporter
}

Obs: {
  Prom: Prometheus
  Loki
  Graf: Grafana
  KSM: "Kube-State-Metrics"
  FB: "Fluent-bit"
}

Nodes.App -> Obs.FB: "logs"
Nodes.App -> Obs.Prom: "metrics"
Nodes.Kubelet -> Obs.Prom
Nodes.NodeExporter -> Obs.Prom
Obs.KSM -> Obs.Prom
Obs.FB -> Obs.Loki
Obs.Prom -> Obs.Graf
Obs.Loki -> Obs.Graf
```

See:
- [Observability architecture](observability.md)

## 4. GitOps structure with ApplicationSets

**Question:** how does ArgoCD discover and deploy stacks from the `K8s/` directory?

```d2
direction: right

Git: "K8s Git repository"

Argo: {
  label: "ArgoCD"
  ASObs: "ApplicationSet: observability"
  ASSec: "ApplicationSet: security"
  ASCi: "ApplicationSet: cicd"
}

Git -> Argo.ASObs
Git -> Argo.ASSec
Git -> Argo.ASCi
```

See:
- [K8s directory architecture](applications.md)
- [GitOps model](../concepts/gitops-model.md)

## 5. Gateway API service exposure

**Question:** how does a browser request reach platform UIs via Gateway API and TLS?

```d2
direction: right

External: {
  Browser: "Browser\nhttps://grafana.<ip>.nip.io"
}

GatewayNS: {
  label: "Gateway API layer\nkube-system"
  Gateway: "Gateway: idp-gateway\nHTTPS:443\nTLS: idp-wildcard-cert"
  Cert: "Certificate: idp-wildcard-cert\n*.nip.io\nIssuer: ca-issuer"
}

Routes: {
  label: "HTTPRoutes"
  HR1: "argocd"
  HR2: "grafana"
  HR3: "vault"
  HR4: "workflows"
  HR5: "sonarqube"
}

Backends: {
  label: "Backends"
  S1: "argocd-server:80"
  S2: "prometheus-grafana:80"
  S3: "vault:8200"
  S4: "argo-workflows-server:2746"
  S5: "sonarqube:9000"
}

External.Browser -> GatewayNS.Gateway: "HTTPS"
GatewayNS.Gateway -> Routes.HR1: "hostname: argocd..."
GatewayNS.Gateway -> Routes.HR2: "hostname: grafana..."
GatewayNS.Gateway -> Routes.HR3: "hostname: vault..."
GatewayNS.Gateway -> Routes.HR4: "hostname: workflows..."
GatewayNS.Gateway -> Routes.HR5: "hostname: sonarqube..."

Routes.HR1 -> Backends.S1
Routes.HR2 -> Backends.S2
Routes.HR3 -> Backends.S3
Routes.HR4 -> Backends.S4
Routes.HR5 -> Backends.S5

GatewayNS.Cert -> GatewayNS.Gateway: "TLS"
```

See:
- [Networking & gateway](../concepts/networking-gateway.md)
