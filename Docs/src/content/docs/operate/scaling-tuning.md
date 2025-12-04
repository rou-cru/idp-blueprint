---
title: Scaling & Tuning
sidebar:
  label: Scaling & Tuning
  order: 4
---
---

## Resource sizing strategy

This demo applies a **three-layer capacity model**: component-level definitions, namespace governance, and priority-based scheduling.

### Layer 1: Component resources

Every component defines explicit `requests` and `limits`:

- **Requests**: guaranteed allocation; scheduler uses this for placement decisions
- **Limits**: maximum allowed; enforced by cgroups

Example from `K8s/observability/fluent-bit/values.yaml`:

```yaml
resources:
  requests:
    cpu: 25m
    memory: 64Mi
  limits:
    cpu: 100m
    memory: 128Mi
```

**Sizing philosophy applied here:**

The sizing strategy varies by component role. DaemonSets like Fluent-bit and Node Exporter use minimal footprints since they run on every node. Control plane components (ArgoCD, operators) receive modest allocations as they are mostly I/O-bound. Observability stack components (Prometheus, Loki) are sized for a 3-node demo running approximately 20 workloads. CI/CD components (Workflows, SonarQube) get larger allocations to handle ephemeral burst capacity.

Check any `*-values.yaml` to see applied sizing.

### Layer 2: Namespace quotas

Each stack has a `governance/resourcequota.yaml` that sets hard ceilings:

```yaml
# K8s/observability/governance/resourcequota.yaml
spec:
  hard:
    requests.cpu: "1500m"
    requests.memory: "2Gi"
    limits.cpu: "4"
    limits.memory: "4Gi"
```

**Purpose**: prevent noisy neighbors; enforce capacity planning.

**Verification**:

```bash
kubectl get resourcequota -A
kubectl describe resourcequota -n observability
```

You'll see current usage vs. hard limits. For example:

```text
requests.cpu: 1050m/1500m
limits.memory: 3600Mi/4Gi
```

### Layer 3: Priority classes

Every workload declares `priorityClassName` (enforced by validation script):

- `platform-infrastructure` (1M): Cilium, cert-manager, Vault, ESO
- `platform-policy` (100k): Kyverno
- `platform-observability` (10k): Prometheus, Grafana, Loki
- `platform-dashboards` (5k): Backstage, Grafana
- `platform-cicd` (7.5k): Argo Workflows, SonarQube
- `cicd-execution` (2.5k): workflow pods
- `user-workloads` (3k): default for apps
- `unclassified-workload` (0): catch-all; preempted first

**When pressure occurs**, Kubernetes evicts lower-priority pods to make room for higher-priority ones.

Check with:

```bash
kubectl get priorityclasses
kubectl get pods -A -o custom-columns=NAME:.metadata.name,PRIORITY:.spec.priorityClassName
```

### Tuning for your environment

1. **Scale up**: adjust quotas in `governance/resourcequota.yaml` per stack
2. **Component sizing**: tweak `resources` in `*-values.yaml` based on load testing
3. **Priority rebalancing**: if different services are critical in your context, adjust `IT/priorityclasses/*.yaml`

This model keeps demo lightweight (~4GB total footprint) while showing production patterns.

### Visual representation

The three-layer model and how the scheduler uses each layer:

![Three-Layer Capacity Model](../assets/diagrams/operate/scaling-three-layers.svg)

### Real cluster verification

See the model in action in the demo cluster:

![Resource Quota Usage](../assets/images/operate/resourcequota-status.png)
*Screenshot of `kubectl describe resourcequota -n observability` showing current usage vs. hard limits*

## Observability knobs

- Prometheus: `retention`, TSDB storage, `scrapeInterval`, drop high‑card labels.
- Loki: pipeline stages, label hygiene, storage backends.
- Dashboards: render fast; prefer recording rules for expensive queries.

## Performance and safety

- Requests/limits tuned per component; quotas/limits per namespace.
- Backpressure: Fluent‑bit buffers; Loki ingestion limits.
- Avoid high cardinality metrics (pod UID, container ID) unless really needed.

## Cost & footprint

- Disable non‑critical components in dev/demo; scale up in staging/prod.
- FinOps labels are already enforced; use them to attribute and decide.
