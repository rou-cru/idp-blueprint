# Subgraph Decision Framework

## Purpose
This memory defines the decision-making framework for creating architecture subgraphs in the IDP Blueprint project. Use these principles to make consistent decisions when designing new subgraphs.

---

## Core Design Philosophy

**Primary Goal:** Graph traversal must be an efficient method for knowledge acquisition and exploration.

**Guiding Question:** "If I start at node X, can I discover everything architecturally relevant to X by following edges?"

---

## Decision 1: Should X be a Node?

### Ask yourself:

1. **Is X a concrete, deployed thing?**
   - YES → Likely a node (e.g., `Prometheus`, `Vault`, `ArgoCD Server`)
   - NO → Probably not a node (e.g., abstract concepts)

2. **Does X represent a restructuring opportunity?**
   - YES → Make it explicit as a node (e.g., `Chart:sonarqube/postgresql` shows PostgreSQL could be extracted/shared)
   - NO → Consider if it adds value

3. **Would hiding X as an edge property make discovery harder?**
   - YES → It should be a node
   - NO → Could be represented as edge metadata

4. **Is X an abstract grouping of other nodes?**
   - YES → **DO NOT** create this node. Model the actual components instead.
   - Example: Don't create "ArgoCD" node; create "ArgoCD Server", "ArgoCD Application Controller", etc.

### Special Cases:

**Subcharts:**
- ALWAYS make subcharts explicit as nodes
- Format: `Chart:parent/subchart`
- Reason: Visibility of refactoring opportunities (shared resources, external services)

**Multi-component systems:**
- Model each actual component, not the abstract system
- Components connect to their real dependencies

**Views:**
- Use for logical grouping/scoping only
- Example: `Workloads View` includes bootstrap infrastructure

---

## Decision 2: What is the Edge Direction?

### Primary Rule: Consumer → Provider (Follow the dependency)

**Ask:** "Who needs whom?"
- The one who NEEDS points TO the one who PROVIDES

### Test Your Direction:

**Scenario 1: Observability/Metrics**
- Q: "Does Prometheus need the workload, or does the workload need Prometheus?"
- A: Workload needs Prometheus (for observability)
- Direction: `Workload → Prometheus` [SCRAPED_BY]

**Scenario 2: Data Sources**
- Q: "Does Grafana need Prometheus, or does Prometheus need Grafana?"
- A: Grafana needs Prometheus (as data source)
- Direction: `Prometheus → Grafana` [FEEDS]

**Scenario 3: Infrastructure Implementation**
- Q: "Does the Gateway need Cilium, or does Cilium need the Gateway?"
- A: Gateway needs Cilium (for implementation)
- Direction: `Cilium → IDP Gateway` [IMPLEMENTS]

**Scenario 4: Gateway Routing**
- Q: "For exploration, what's the natural flow?"
- A: "What does this gateway expose?" (Gateway → Routes → Backends)
- Direction: `IDP Gateway → HTTPRoute → Workload`
- Special case: Gateway is entry point, direction optimized for discoverability

### Exploration Test (Critical):

Imagine you're investigating from node X:
1. Following outgoing edges from X, do you discover X's dependencies? ✓
2. Following incoming edges to X, do you discover what depends on X? ✓

If either fails, reconsider direction.

---

## Decision 3: Edge Label

### Constraints:
- **1 word preferred**
- **2 words acceptable** if it significantly improves clarity
- **3+ words forbidden**

### Selection Process:

1. **What is the relationship type?**
   - Deployment: `DEPLOYS`, `RECONCILES`
   - Data flow: `FEEDS`, `SENDS_TO`
   - Dependency: `USES`, `REQUIRES`
   - Implementation: `IMPLEMENTS`
   - Exposure: `SCRAPED_BY`, `ROUTES`, `TARGETS`
   - Management: `MANAGES`, `SYNCS_TO`
   - Containment: `HOSTS`, `PROVIDES`, `INCLUDES`

2. **Does it read naturally with the direction?**
   - Test: "X [LABEL] Y" should make sense
   - Example: "Cilium IMPLEMENTS IDP Gateway" ✓
   - Example: "Workload SCRAPED_BY Prometheus" ✓

3. **Is it consistent with similar relationships in the graph?**

---

## Decision 4: Bootstrap vs GitOps Charts

### Ask: "How is this chart deployed?"

**Bootstrap (Helm install directly):**
```
Workloads View → Chart:X [INCLUDES]
Chart:X → Workload [DEPLOYS]
```
- Examples: `cilium`, `vault`, `cert-manager`, `argocd`, `external-secrets`

**GitOps (Managed by ArgoCD):**
```
ArgoCD Application Controller → Chart:X [RECONCILES]
Chart:X → Workload [DEPLOYS]
```
- NOT included in Workloads View
- Discoverable via ArgoCD Application Controller
- Examples: `kyverno`, `kube-prometheus-stack`, `sonarqube`, etc.

### How to determine:
- Check `Task/bootstrap.yaml` for `helm install` commands → Bootstrap
- Check `K8s/**/applicationset-*.yaml` → GitOps

---

## Decision 5: When to Show ESO → SecretStore Edge

### Rule: Only show edge when there's actual consumption

**Ask:** "Does any workload consume secrets from this SecretStore?"

- YES → Include both:
  ```
  External-Secrets-Operator → SecretStore:X [SYNCS_TO]
  SecretStore:X → Workload [FEEDS]
  ```
- NO → Do not include `ESO → SecretStore` edge (reduces noise)

### Reason:
The goal is showing actual data flow, not potential/configured infrastructure.

---

## Decision 6: Cluster-Scoped vs Namespaced Resources

### Cluster-Scoped (shared infrastructure):
```
K3d-Cluster → Resource [HOSTS/REQUIRES/PROVIDES]
```
- Examples: `CA ClusterIssuer`, `Cilium`, `IDP Gateway`
- Check: Does resource have `metadata.namespace`? NO → Cluster-scoped

### Namespaced:
```
Namespace:X → Resource [HOSTS]
```
- Examples: Charts, Workloads, HTTPRoutes, SecretStores
- Check: Does resource have `metadata.namespace`? YES → Namespaced

---

## Decision-Making Workflow

When adding a new component to a subgraph:

1. **Identify the component's deployment method**
   - Bootstrap? GitOps? Other?
   - Determines relationship to Workloads View and/or ArgoCD

2. **List all dependencies (what it NEEDS)**
   - Data sources, secrets, infrastructure
   - Create edges: `Component → Dependency`

3. **List all consumers (what NEEDS it)**
   - Represented by incoming edges from consumers
   - Review if any new consumer nodes needed

4. **Check for subcharts/sub-components**
   - Make explicit as separate nodes
   - Connect via `SUBCHART` → `DEPLOYS` pattern

5. **Determine namespace/cluster scope**
   - Affects relationship to `K3d-Cluster` vs `Namespace:X`

6. **Verify traversal works both ways**
   - From component → dependencies: ✓
   - From infrastructure → component: ✓

---

## Common Patterns

### Pattern: Standard Workload
```
Workload → Database [USES]
Workload → Prometheus [SCRAPED_BY]
Workload ← HTTPRoute [TARGETS]
HTTPRoute ← IDP Gateway [ROUTES]
Workload ← SecretStore:X [FEEDS]
Workload ← Chart:X [DEPLOYS]
```

### Pattern: GitOps Deployment
```
ArgoCD Application Controller → Chart:X [RECONCILES]
Chart:X → Workload [DEPLOYS]
Chart:X ← Namespace:Y [HOSTS]
```

### Pattern: Chart with Subchart
```
Chart:parent → Chart:parent/subchart [SUBCHART]
Chart:parent/subchart → SubWorkload [DEPLOYS]
MainWorkload → SubWorkload [USES]
```

### Pattern: Shared Infrastructure
```
K3d-Cluster → Infrastructure [REQUIRES/HOSTS]
Infrastructure → Consumer1 [IMPLEMENTS/FEEDS]
Infrastructure → Consumer2 [IMPLEMENTS/FEEDS]
```

---

## Validation Questions

Before finalizing additions to a subgraph:

1. **Can I discover this component's dependencies by following outgoing edges?**
2. **Can I discover what depends on this component by following incoming edges?**
3. **Are all subcharts explicit (not hidden in parent charts)?**
4. **Do edge directions follow consumer → provider?**
5. **Are edge labels ≤2 words?**
6. **Did I avoid creating abstract grouping nodes?**
7. **Is the component correctly associated with bootstrap or GitOps deployment?**
8. **Are cluster-scoped vs namespaced resources correctly modeled?**

---

## Key Insight

The graph is not a documentation artifact—it's an **exploration tool**.

Every decision should optimize for:
- **Discoverability:** Can you find related components by traversal?
- **Understanding:** Do relationships reveal true dependencies?
- **Planning:** Are restructuring opportunities visible?

When in doubt, choose the option that makes exploration more efficient.
