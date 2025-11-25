# Memory Graph Corruption Prevention

## Critical Error Pattern: Adding "Verification" Observations

### What NOT to Do

**NEVER add observations that:**

1. **Verify/confirm existing data** - "verified in cluster", "confirmed", "actual_version"
2. **Duplicate configuration** - Repeating values.yaml content, chart versions already present
3. **Document file paths** - "values_path:", "image:", paths that don't add architectural value
4. **Add runtime details** - Resource limits, replicas, tolerations (belongs in values.yaml)
5. **Create audit metadata** - "deployment_name: X (verified in cluster)"

### Why This Is Critically Wrong

**The Memory Graph is NOT:**
- A verification log
- A configuration backup
- A deployment audit trail
- A documentation of what you checked

**The Memory Graph IS:**
- A traversal tool for discovering architecture
- A knowledge network linking deployables → concepts → docs
- A system for answering: "What depends on X?" and "What does X depend on?"

### Consequence of Violation

When you add verification/audit observations:

1. **Signal pollution** - Real architectural facts buried in noise
2. **False confidence** - "verified" suggests authority but ages instantly
3. **Duplication** - Information exists in code/cluster, no need to mirror
4. **Forced deletion** - Only way to clean is DELETE entity + RECREATE (loses history)
5. **Graph degradation** - Each bad observation makes traversal less efficient

**Example of what happened:**

```
Chart:cilium had:
- chart_version: 1.18.2  ✓ VALID (source of truth reference)
- repository: https://helm.cilium.io/  ✓ VALID (where to find it)

Added incorrectly:
- actual_version: 1.18.2 (verified in cluster)  ✗ AUDIT/VERIFICATION
- image: quay.io/cilium/cilium:v1.18.2  ✗ RUNTIME DETAIL
- values_path: IT/cilium/values.yaml  ✗ FILE PATH (no traversal value)

Result: Had to DELETE Chart:cilium entity completely and recreate clean.
```

### The Delete-Recreate Cost

Because MCP memory tools don't support `delete_observations` reliably:

1. Entity must be fully deleted (loses all relations)
2. Entity must be recreated with clean observations
3. All relations must be manually recreated
4. Risk of breaking graph connectivity if relations forgotten

**This is EXPENSIVE and ERROR-PRONE.**

### Correct Approach When Auditing

When you find discrepancies between documentation and reality:

**DO:**
- Document findings in audit report (ephemeral, for user action)
- Update documentation files directly
- If observation is genuinely WRONG, update it (e.g., wrong chart version)

**DON'T:**
- Add "verified" observations to confirm truth
- Add observations documenting what you checked
- Create entities for audit metadata
- Duplicate information that lives in code

### Decision Tree: Should I Add This Observation?

```
Is this observation...

├─ Verifying existing data?
│  └─ NO → Don't add it
│
├─ Duplicating values.yaml?
│  └─ YES → Don't add it
│
├─ A file path with no traversal value?
│  └─ YES → Don't add it
│
├─ Runtime config (resources, replicas)?
│  └─ YES → Don't add it
│
├─ Helping traverse from concept → implementation → docs?
│  └─ NO → Don't add it
│  └─ YES → Consider adding
│
└─ Short fact (role, namespace, key integration)?
   └─ YES → Probably valid
```

### Valid Observation Examples

```yaml
Chart:cilium:
  - chart_version: 1.18.2  # Source of truth reference
  - namespace: kube-system  # Deployment scope
  - repository: https://helm.cilium.io/  # Where to get it

External-Secrets-Operator:
  - deployment_type: Deployment  # What kind of workload
  - namespace: external-secrets-system  # Where it lives
  - Syncs secrets from Vault to Kubernetes  # What it does
```

### Invalid Observation Examples

```yaml
Chart:cilium:
  - actual_version: 1.18.2 (verified in cluster)  # AUDIT NOISE
  - image: quay.io/cilium/cilium:v1.18.2  # RUNTIME DETAIL
  - values_path: IT/cilium/values.yaml  # FILE PATH

kube-state-metrics:
  - deployment_name: prometheus-kube-state-metrics (verified)  # VERIFICATION
  - role: Exposes metrics  # REDUNDANT (relation exists)
  - scraped_by: Prometheus  # REDUNDANT (relation exists)
```

### Remember

**Graph observations are for ARCHITECTURE, not AUDITING.**

If you're documenting what you verified/checked/confirmed, you're polluting the graph.

**Ask yourself:** "Will this help someone traverse the graph to understand the system?"
- NO → Don't add it
- YES → Keep it minimal

The graph is a knowledge network, not a changelog.
