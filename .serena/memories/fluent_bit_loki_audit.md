# Fluent Bit to Loki Pipeline Audit - December 23, 2025

## Executive Summary
Complete logging pipeline is broken. Fluent Bit is in CrashLoopBackOff, Loki has NO data (never received logs), and Grafana cannot query anything.

## Current State

### Fluent Bit Status
- **State**: CrashLoopBackOff (2 pods, 220+ restarts each)
- **Error**: `[error] [output:loki:loki.0] invalid label key, the name must start with '$'`
- **Uptime**: Broken for 18 hours since commit f1dc7dd
- **Version**: 4.1.0

### Loki Status
- **State**: Running (2/2 containers)
- **Data**: EMPTY - zero logs ever received
- **Storage**: 2Gi PVC (persistent)
- **Uptime**: 4d12h (older than Fluent Bit crash)
- **Key Finding**: Loki never received logs even BEFORE the recent change

### Grafana-Loki Integration
- **Datasource**: Configured correctly (uid: Loki, proxy mode)
- **Connectivity**: OK
- **Labels**: Empty array (no streams)
- **Queries**: Return zero results (expected, Loki is empty)

## Log Sources Mapped

### Current Pod Inventory (Potential Log Sources)
- **argo-events** namespace: 6 pods (controller, eventbus cluster, webhook, sensor)
- **argocd** namespace: 6 pods (controller, repo-server, server, redis, notifications, applicationset)
- **backstage** namespace: 3 pods (backstage, postgresql, dex)
- **cert-manager** namespace: 3 pods
- **cicd** namespace: 4 pods (argo-workflows, sonarqube + postgresql) - NOTE: sonarqube in CrashLoopBackOff
- **default** namespace: 1 pod (httpbin)
- **external-secrets-system**: 2 pods
- **kube-system**: 3+ pods (Cilium daemonsets)
- **observability** namespace: Fluent Bit (broken), Prometheus stack, Loki

**Total**: ~50+ pods generating logs that should be collected

### Fluent Bit Input Configuration
```
[INPUT]
    Name tail
    Path /var/log/containers/*.log
    multiline.parser cri
    Tag kube.*
```
**Coverage**: Configured to collect ALL container logs via standard Kubernetes log path

## Root Cause Analysis

### Problem #1: Current Crash (Since f1dc7dd - 18h ago)
**Symptom**: Fluent Bit crashes immediately on startup

**Error**:
```
[error] [output:loki:loki.0] invalid label key, the name must start with '$'
[error] [output:loki:loki.0] cannot initialize configuration
```

**Root Cause**: Incorrect `label_keys` syntax in OUTPUT configuration
```yaml
# CURRENT (BROKEN):
labels job=fluentbit
label_keys namespace, pod, container, app
```

According to Fluent Bit v4 documentation, `label_keys` requires `$` prefix for record accessors:
- Correct: `label_keys $namespace,$pod,$container,$app`
- OR use `labels` with explicit mapping: `labels job=fluentbit,namespace=$namespace,pod=$pod`

**Additional Issue**: Spacing after commas may also cause parsing problems in some versions

### Problem #2: Original Issue (Before the change)
**Symptom**: Fluent Bit ran without crashing BUT Grafana couldn't query logs

**Previous Configuration** (commit f1dc7dd~1):
```yaml
# FILTER:
Rename kubernetes.namespace_name namespace
Rename kubernetes.pod_name pod
Rename kubernetes.container_name container

# OUTPUT:
labels job=fluentbit, namespace=$namespace, pod=$pod, container=$container
```

**Suspected Root Causes** (to be verified):
1. **Variable Resolution**: The `$namespace`, `$pod`, `$container` variables may not have resolved correctly
   - Fluent Bit `labels` parameter expects record accessor syntax
   - Simple field names may not work with `$` prefix after `Rename`
   
2. **Label Cardinality**: Using `pod=$pod` creates high-cardinality labels
   - Loki may have been rejecting streams
   - No error logs visible (need to check if Fluent Bit had output errors)

3. **Missing Data Path**: Fields were renamed but may not exist at top level for `$variable` accessor

**Why the Change Was Made**:
Commit f1dc7dd tried to fix this by:
- Changing `Rename` → `Copy` (preserve kubernetes.* metadata)
- Adding `app` label extraction logic
- Switching from `labels $variable` to `label_keys` (simpler syntax)
- BUT: Used incorrect `label_keys` syntax

## Configuration Comparison

### Before (f1dc7dd~1) - "Worked" but no logs in Grafana
```yaml
[FILTER]
    Name modify
    Rename kubernetes.namespace_name namespace
    Rename kubernetes.pod_name pod
    Rename kubernetes.container_name container

[OUTPUT]
    labels job=fluentbit, namespace=$namespace, pod=$pod, container=$container
    auto_kubernetes_labels off
```

### After (f1dc7dd) - Crashes
```yaml
[FILTER]
    Name modify
    Copy kubernetes.namespace_name namespace
    Copy kubernetes.pod_name pod
    Copy kubernetes.container_name container
    Copy kubernetes.labels.app app
    [Conditional app fallbacks...]

[OUTPUT]
    labels job=fluentbit
    label_keys namespace, pod, container, app
```

## Technical Details

### Fluent Bit v4 Label Syntax (from official docs)
1. **Static labels**: `labels job=fluentbit,env=prod`
2. **Dynamic labels with custom names**: `labels job=fluentbit,ns=$namespace`
3. **label_keys with record accessors**: `label_keys $namespace,$pod` (uses field name as label name)

### Key Differences
- `labels`: Allows custom label names, requires explicit `key=$field` format
- `label_keys`: Simpler, uses record key name directly as label, still needs `$` for accessors
- Both support `$` syntax for nested/dynamic values

## Next Steps Required

1. **Immediate Fix**: Correct the label_keys syntax to stop crashes
2. **Validation**: Test if $variable syntax works with top-level fields
3. **Alternative**: Consider reverting to `labels` syntax with proper field accessors
4. **Loki Testing**: Verify Loki can accept and index the labels properly
5. **Grafana Testing**: Confirm queries work end-to-end
6. **Cardinality Analysis**: Evaluate if `pod` label should be used (very high cardinality)

## Open Questions

1. Why did previous config not send logs to Loki? (Need to check historical Fluent Bit logs if available)
2. Is `pod` label acceptable for this environment's scale? (Currently ~50 pods)
3. Should we use `auto_kubernetes_labels on` instead of manual label selection?
4. Do we need the `app` label extraction logic or is it over-engineering?

## Test Strategy

1. Fix syntax and verify Fluent Bit starts
2. Check Fluent Bit logs for successful Loki push
3. Query Loki API directly for label existence
4. Test Grafana queries with various LogQL patterns
5. Monitor for label cardinality warnings in Loki