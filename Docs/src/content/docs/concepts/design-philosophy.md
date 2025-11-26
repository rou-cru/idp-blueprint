---
title: Design Philosophy
sidebar:
  label: Design Philosophy
  order: 1
---

This document describes the core design philosophies that guide the architecture and
  implementation of the IDP Blueprint platform. These aren't just abstract principles—they
  manifest in concrete technical decisions throughout the stack.

## The Five Philosophies

The platform is built on five interconnected philosophies:

1. **Declarative Configuration:** Describe the desired state, let automation achieve it
2. **Infrastructure as Code:** Infrastructure is defined in version-controlled code
3. **GitOps:** Git is the single source of truth for system state
4. **Security as Code:** Security policies are code, not manual checklists
5. **Observability as Code:** Monitoring and alerting configurations are declarative and versioned

These philosophies reinforce each other. GitOps builds on Infrastructure as Code. Security as Code leverages declarative configuration. Observability as Code makes the entire system's behavior visible.

## 1. Declarative Configuration

### What It Means

Instead of writing scripts that execute a sequence of steps (imperative), you declare what the desired end state should look like. The system figures out how to achieve that state.

**Imperative:**

```bash
kubectl create namespace my-app
kubectl create secret generic db-password --from-literal=password=secret
kubectl apply -f deployment.yaml
```

**Declarative:**

```yaml
# All resources defined in YAML
apiVersion: v1
kind: Namespace
metadata:
  name: my-app
---
apiVersion: v1
kind: Secret
metadata:
  name: db-password
  namespace: my-app
stringData:
  password: secret
---
apiVersion: apps/v1
kind: Deployment
# ...
```

### How It Manifests in This Platform

- **Kubernetes Manifests:** All resources are defined declaratively as YAML
- **Helm Charts:** Applications are templated declaratively, not scripted
- **ArgoCD Applications:** Desired state is defined in Git, ArgoCD reconciles
- **Kyverno Policies:** Policies are ClusterPolicy CRDs, not imperative validation scripts
- **ServiceMonitors:** Prometheus scrape configuration is declarative CRDs, not config files

**Benefits:**

- **Idempotent:** Applying the same manifest multiple times produces the same result
- **Self-Healing:** If the current state drifts from desired state, the system automatically corrects it
- **Predictable:** You can reason about what the system will do by reading the manifests

## 2. Infrastructure as Code

### What It Means

Infrastructure (networks, compute, storage, services) is defined in code files rather than configured through UIs or manual processes.

### How It Manifests in This Platform

- **Helm Values:** Every component's configuration is in `values.yaml` files
- **Kubernetes Resources:** Namespaces, RBAC, PriorityClasses, NetworkPolicies (when implemented) are all defined as code
- **Terraform/Devbox (External):** The cluster itself can be provisioned via code (k3d, Terraform modules, etc.)

**This repository contains:**

- `IT/`: Infrastructure components (Cilium, Vault, ArgoCD, etc.)
- `K8s/`: Application-layer components (observability, CI/CD)
- `Policies/`: Governance policies as Kyverno ClusterPolicies

Every environment configuration exists as code, not tribal knowledge or manual steps.

**Benefits:**

- **Reproducibility:** Destroy and recreate the entire platform with one command
- **Version Control:** Every change is tracked in Git with full history
- **Code Review:** Infrastructure changes go through the same review process as application code
- **Documentation:** The code itself documents how the infrastructure is configured

## 3. GitOps

### What It Means

Git is the single source of truth for the desired state of the system. A GitOps operator (ArgoCD) continuously monitors Git and ensures the cluster matches what's defined there.

### How It Manifests in This Platform

- **ArgoCD:** Watches this repository and deploys resources automatically
- **Self-Heal:** If someone manually changes a resource, ArgoCD reverts it to match Git
- **Sync Waves:** Dependencies are handled declaratively via
  `argocd.argoproj.io/sync-wave` annotations (see
  [`GitOps, Policy, and Eventing`](gitops-model.md) for the wave model used
  here)
- **ApplicationSets:** Dynamic application generation from templates (see
  [`GitOps, Policy, and Eventing`](gitops-model.md) for the App‑of‑AppSets
  pattern)

**The GitOps Flow:**

![GitOps Flow](gitops-flow.svg)

This creates a feedback loop:

1. **Desired State:** Defined in Git
2. **Observed State:** What's actually running (visible via Prometheus/Grafana)
3. **Actionable Insights:** Identify drift, trigger repairs

**Benefits:**

- **Audit Trail:** Every change is a Git commit with author, timestamp, and rationale
- **Rollback:** `git revert` to undo changes
Disaster recovery becomes a matter of re-deploying from Git if the cluster is lost. This model fosters collaboration by allowing multiple engineers to propose changes via pull requests, ensuring consistency by eliminating environment-specific manual steps.

**Next Steps:**

- See [GitOps Model](gitops-model.md) for ApplicationSets, sync waves, and the App-of-AppSets pattern
- See [Application Architecture](../architecture/applications.md) for technical implementation details

## 4. Security as Code

### What It Means

Security policies, access controls, and compliance requirements are defined as code and automatically enforced, not manually checked.

### How It Manifests in This Platform

- **Kyverno Policies:** Security and governance rules are ClusterPolicy CRDs:
  - Require resource limits
  - Enforce namespace labels for cost attribution
  - Validate image sources
  - Audit for best practices

- **RBAC:** Kubernetes role-based access control defined as YAML

- **NetworkPolicies (Future):** Network segmentation rules as code

- **Secrets Management:** Secrets flow through Vault and External Secrets, never hardcoded

- **Image Scanning:** Trivy policies can block vulnerable images in CI

**The philosophy in action:**

Instead of a security checklist that engineers manually follow ("Did you add resource limits?"), Kyverno enforces it automatically. Violations are caught at admission time or reported via PolicyReports.

**Current Mode:**

Most policies run in `audit` mode, reporting violations without blocking. This is intentional—it guides developers without creating friction. As the platform matures, policies can migrate to `enforce` mode.

**Benefits:**

- **Consistency:** Policies are enforced uniformly across all resources
- **Auditability:** PolicyReports show compliance status over time
- **Shift Left:** Security issues are caught early, not in production
- **No Toil:** Automated enforcement eliminates manual security reviews for basic issues

## 5. Observability as Code

### What It Means

Monitoring, logging, and alerting configurations are declarative and version-controlled, not configured through UIs.

### How It Manifests in This Platform

- **ServiceMonitors:** Prometheus scrape targets are defined as CRDs. Deploy a service with a ServiceMonitor, Prometheus discovers it automatically.

- **PrometheusRules:** Alerting rules are defined as CRDs.

- **Grafana Dashboards:** Stored as ConfigMaps (code), auto-loaded via sidecar.

- **Loki Configuration:** Log parsing, retention, and storage defined in `values.yaml`.

- **Fluent-bit Configuration:** Log collection rules defined declaratively.

**Example:**

A new service wants to expose metrics. Instead of manually updating Prometheus config files:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-app-metrics
spec:
  selector:
    matchLabels:
      app: my-app
  endpoints:
  - port: metrics
    interval: 30s
```

Prometheus discovers this ServiceMonitor automatically and starts scraping.

**Benefits:**

- **Version Control:** Dashboards and alerts are tracked in Git
- **Reproducibility:** Observability config deploys alongside applications
- **Collaboration:** Changes to alerts and dashboards go through code review
- **Self-Service:** Developers define their own metrics and dashboards

## How These Philosophies Reinforce Each Other

The five philosophies aren't independent—they form an interconnected system:

```
Infrastructure as Code
        ↓
   (defines)
        ↓
Declarative Configuration
        ↓
   (enables)
        ↓
      GitOps
     ↙     ↘
Security    Observability
as Code     as Code
     ↘     ↙
  (provide)
        ↓
Actionable Feedback Loop
```

**Example Flow:**

1. A developer defines a new application (Declarative Configuration)
2. The application manifest includes a ServiceMonitor (Observability as Code)
3. The manifest has Kyverno policy annotations (Security as Code)
4. Everything is committed to Git (Infrastructure as Code)
5. ArgoCD detects the change and deploys it (GitOps)
6. Prometheus scrapes metrics automatically (Observability as Code)
7. Kyverno validates resource limits (Security as Code)

The entire process is automated, auditable, and reproducible. No manual steps.

## What This Means in Practice

If you're working with this platform:

- **Don't:** SSH into nodes and run `kubectl` commands to fix issues
- **Do:** Commit a fix to Git and let ArgoCD reconcile

- **Don't:** Click through Prometheus UI to configure scrape targets
- **Do:** Define a ServiceMonitor CRD in your application manifest

- **Don't:** Manually create secrets and inject them into pods
- **Do:** Store secrets in Vault, define ExternalSecrets, reference the synced Kubernetes Secret

- **Don't:** Document security policies in a wiki
- **Do:** Define Kyverno ClusterPolicies that automatically enforce them

## Trade-offs

These philosophies create constraints:

- **Learning Curve:** Understanding declarative patterns and GitOps requires initial investment
- **Indirection:** Debugging can be harder when automation is doing things behind the scenes
- **Boilerplate:** Declarative manifests can be verbose compared to imperative scripts

The platform accepts these trade-offs in exchange for reproducibility, auditability, and automation.

## References

- [GitOps Model](gitops-model.md): Deep dive into the GitOps workflow
- [Security & Policy Model](security-policy-model.md): How Security as Code manifests
- [Observability Model](../architecture/observability.md): How Observability as Code works
- [ArgoCD Component](../components/infrastructure/argocd/index.md): GitOps engine
- [Kyverno Component](../components/policy/kyverno/index.md): Policy engine
