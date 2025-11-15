# Secrets Management — Source of truth vs. consumption

Principle: workloads never talk to Vault. They consume Kubernetes Secrets that are synced from Vault by External Secrets Operator (ESO). This keeps concerns clean and manifests safe to version.

## The pattern

```d2
direction: right

Vault: "KV v2 (secret/*)"
ESO: "External Secrets Operator"

NS: {
  label: "Namespace"
  SA: "ServiceAccount: external-secrets"
  Store: "(Cluster)SecretStore → Vault auth"
  ES: "ExternalSecret → K8s Secret"
}

Vault -> ESO: read
ESO -> NS.ES: reconcile
NS.ES -> NS: Secret
```

Why it works:
- Commit ExternalSecret objects (not literal values).
- ESO authenticates to Vault using per‑namespace roles and writes/update the K8s Secret.
- Charts can still add their own keys by using `creationPolicy: Merge`.

![Vault consumer](../assets/images/verify/grafana-home.jpg){ loading=lazy }

## Contracts and tags

- Every Namespace carries labels: `owner`, `business-unit`, `environment`, `app.kubernetes.io/part-of`.
- Kyverno can enforce presence and propagate common labels to workloads (mutate/generate — planned hardening).

## Failure modes to think about

- Vault unreachable → last good Secret remains; ESO will retry.
- Wrong path in ExternalSecret → target Secret not updated (alerts should surface it).
- Chart writes sensitive fields on first boot → keep `creationPolicy: Merge` to avoid clobbering.
