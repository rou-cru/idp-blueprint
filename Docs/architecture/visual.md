# Architecture visuals — key flows

This page collects a small set of diagrams that show how the main control loops and data paths work inside the platform. Use it as a visual reference after you have read:

- [Architecture overview](overview.md)
- [GitOps model](../concepts/gitops-model.md)
- [Security & policy model](../concepts/security-policy-model.md)

Each diagram focuses on a single question and links back to the relevant documentation.

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
shape: sequence_diagram
App: Application Pod
K8S: Kubernetes Secret
ES: ExternalSecret CR
ESO: External Secrets Operator
SS: SecretStore
Vault

App -> K8S: Needs Secret
K8S -> App: Not found / outdated
ESO -> ES: Watch ExternalSecret
ES -> ESO: secretStoreRef: vault-*
ESO -> SS: Read SecretStore (vault, k8s auth)
SS -> ESO: Provider config
ESO -> Vault: Request secret
Vault -> ESO: Secret data
ESO -> K8S: Create/Update Secret
K8S -> App: Mounted in Pod
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
direction: down

External: {
  Browser: "Browser: https://grafana.<ip>.nip.io"
}

GatewayNS: {
  label: "Gateway API layer - kube-system"
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
  S1: "argocd-server:80"
  S2: "prometheus-grafana:80"
  S3: "vault:8200"
  S4: "argo-workflows-server:2746"
  S5: "sonarqube:9000"
}

External.Browser -> GatewayNS.Gateway: HTTPS
GatewayNS.Gateway -> Routes.HR1: hostname route
GatewayNS.Gateway -> Routes.HR2
GatewayNS.Gateway -> Routes.HR3
GatewayNS.Gateway -> Routes.HR4
GatewayNS.Gateway -> Routes.HR5
Routes.HR1 -> Backends.S1
Routes.HR2 -> Backends.S2
Routes.HR3 -> Backends.S3
Routes.HR4 -> Backends.S4
Routes.HR5 -> Backends.S5
GatewayNS.Cert -> GatewayNS.Gateway: TLS
```

See:
- [Networking & gateway](../concepts/networking-gateway.md)
