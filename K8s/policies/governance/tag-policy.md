# Kubernetes Tagging Policy

This document defines the standard metadata policy for all Kubernetes resources within
this project. The goal is to ensure operational consistency, enable FinOps capabilities,
and improve discoverability and automation.

## Labels vs. Annotations: The Core Principle

A crucial distinction determines whether a piece of metadata should be a label or an
annotation:

- **Use a Label** when you need to **SELECT, FILTER, or GROUP** resources. Labels are
  indexed by the Kubernetes API server and are fundamental to the control plane (e.g.,
  for `kubectl -l`, Service selectors, NetworkPolicies). If you need to query for a set
  of resources based on a value, it must be a label.

- **Use an Annotation** for arbitrary metadata intended to be **READ by HUMANS or
  EXTERNAL TOOLS**. This data is not used for selection. It is perfect for storing
  descriptions, URLs, or contact information that automation scripts or documentation
  generators will consume.

---

## Specification Table

|#|Tag|Type|Class|Meaning|Example|Prop?|
|-|---|----|-----|-------|-------|-----|
|1|app.kubernetes.io/name|Label|OffK8s|App name|vault|Yes|
|2|app.kubernetes.io/instance|Label|OffK8s|Deployment id|vault-demo|Yes|
|3|app.kubernetes.io/version|Label|OffK8s|Semantic version|1.15.0|No|
|4|app.kubernetes.io/component|Label|OffK8s|Role in stack|cni|Yes|
|5|app.kubernetes.io/part-of|Label|OffK8s|Parent app|idp|Yes|
|6|owner|Label|DeFacto|Accountable team|platform|Yes|
|7|business-unit|Label|DeFacto|Chargeback unit|engineering|Yes|
|8|environment|Label|DeFacto|Execution env|prod|Yes|
|9|description|Annotation|Project|Human summary|Primary issuer|No|
|10|contact|Annotation|Project|Incident channel|#platform-alerts|Yes|
|11|documentation|Annotation|Project|Runbook link|<https://wiki>|Yes|

---

## Detailed Policy

### Propagation

Common metadata (like `owner`, `environment`, `business-unit`) should be set on the
`Namespace` object. A policy engine like **Kyverno** is expected to automatically
propagate these to all resources within that namespace.

### Label Details

1. **`app.kubernetes.io/name`**: The application's name (e.g., `vault`).
2. **`app.kubernetes.io/instance`**: Unique instance name, often combining name and
   environment (e.g., `vault-demo`).
3. **`app.kubernetes.io/version`**: The deployed version. **Must not** be used in
   `spec.selector.matchLabels`.
4. **`app.kubernetes.io/component`**: The role this application plays (e.g., `cni`,
   `secret-manager`).
5. **`app.kubernetes.io/part-of`**: The parent application. For this project, the value
   is `idp`.
6. **`owner`**: The team responsible. Must be a team name, not an individual.
7. **`business-unit`**: The organizational department for FinOps.
8. **`environment`**: The environment type. This project uses `demo` to signify its
   ephemeral and testing nature, distinct from permanent environments like `dev` or
   `prod`.

### Annotation Details

1. **`description`**: A human-readable explanation of the resource. This will be used
   by `yq` to auto-generate documentation.
2. **`contact`**: A stable contact point for alerts, preferably a team channel.
3. **`documentation`**: A direct URL to relevant technical documentation.
