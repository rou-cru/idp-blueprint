# Fluent Bit to Loki Technical Analysis - December 23, 2025

## Current Working State

### What Works
- ✅ Fluent Bit pods running (2/2 ready)
- ✅ Logs flowing to Loki in real-time
- ✅ All Kubernetes metadata captured in log JSON body
- ✅ LogQL can parse and filter logs using `| json`
- ✅ ~50+ pods' logs being collected

### What Doesn't Work
- ❌ Loki labels are wrong: only `job`, `service_name`, `stream`
- ❌ Public dashboards expect: `namespace`, `container`, `stream` as labels
- ❌ Dashboards won't work without modifying queries (not viable - imported dashboards)

## Root Cause Identified

### Current Fluent Bit Configuration (BROKEN)
```yaml
[FILTER]
    Name modify
    Copy kubernetes.namespace_name namespace
    Copy kubernetes.pod_name pod
    Copy kubernetes.container_name container
    Add stream stdout

[OUTPUT]
    labels job=fluentbit,namespace=$namespace,container=$container,stream=stdout
```

**Problem**: 
- `Copy` creates top-level fields `namespace`, `pod`, `container`
- But `$namespace` syntax doesn't access these copied fields
- Fields may not exist or aren't accessible when OUTPUT processes them
- Result: Labels fail silently, only `job` and `stream=stdout` (static) work

### Evidence from Loki Logs
```
for stream: {__stream_shard__="0", job="fluentbit", service_name="fluentbit", stream="stdout"}
```
- No `namespace` or `container` labels present
- Mysterious `service_name="fluentbit"` (where does this come from?)

### What Actually Works (Per Documentation)
Fluent Bit v4 supports **direct nested field access** with bracket notation:
```yaml
labels job=fluentbit,namespace=$kubernetes['namespace_name'],container=$kubernetes['container_name']
```

This accesses the kubernetes map fields directly without needing `Copy` filter.

## Proposed Solution

### Option A: Use Nested Field Access (RECOMMENDED)
```yaml
# REMOVE the modify filter for namespace/pod/container Copy
# Keep only Lua filter for removing high-cardinality labels

[OUTPUT]
    Name loki
    Match *
    Host loki.observability.svc.cluster.local
    Port 3100
    line_format json
    # Access nested kubernetes fields directly
    labels job=fluentbit,namespace=$kubernetes['namespace_name'],container=$kubernetes['container_name']
    # Note: stream comes from the log itself (stdout/stderr)
    # We may need to add: stream=$stream or similar if it exists in record
    Retry_Limit 5
    compress gzip
    Buffer_Size 64k
```

**Pros**:
- Simpler config (removes unnecessary filter)
- Direct access to source data
- Documented and supported syntax

**Cons**:
- Need to verify `stream` field handling (stdout/stderr)

### Option B: Fix the Copy + Variable Reference
Keep modify filter but fix variable syntax - research if `$namespace` works after Copy.

**Cons**:
- More complex
- Adds processing overhead
- Documentation suggests direct access is preferred

## Open Questions to Resolve

1. **Stream field**: How to capture stdout/stderr?
   - Is it in `$stream` field already?
   - Do we need `Add stream stdout` or can we extract it?
   - Check if kubernetes filter provides this

2. **service_name label**: Where does `service_name="fluentbit"` come from?
   - Not in our config
   - Is it auto-added by Loki output plugin?
   - Can we remove it?

3. **Label cardinality**: Should we include `pod` label?
   - Dashboard query shows: `{namespace=~"$namespace", stream=~"$stream", container=~"$container"}`
   - No `pod` variable in dashboard
   - Pod names are high-cardinality (~50+ unique values)
   - **Recommendation**: Don't add pod label unless dashboards need it

4. **Static stream value**: Current config has `stream=stdout` (static)
   - This is WRONG - loses stderr logs distinction
   - Need dynamic stream value from actual log stream

## Research Needed Before Implementation

1. Check Fluent Bit kubernetes filter output structure
   - Does it provide `stream` field?
   - Verify exact field names available

2. Test syntax in non-prod or locally:
   - `$kubernetes['namespace_name']` 
   - `$kubernetes['container_name']`
   - Stream field access pattern

3. Review Loki output plugin source/docs:
   - Why is `service_name` auto-added?
   - Can we control it?

## Implementation Plan (Draft)

1. **Research Phase**:
   - Read Fluent Bit kubernetes filter docs
   - Verify field structure in logs
   - Test syntax validity

2. **Config Changes**:
   - Remove modify filter Copy operations
   - Update OUTPUT labels to use `$kubernetes['field']` syntax
   - Fix stream to be dynamic

3. **Validation**:
   - Verify Fluent Bit starts without errors
   - Check Loki receives correct labels via API
   - Test public dashboard queries work as-is

4. **Rollback Plan**:
   - Keep current working config documented
   - If new config fails, revert immediately
   - Loki will accept new labels even if old data had different labels (streams are separate)

## Success Criteria

- ✅ Loki labels include: `job`, `namespace`, `container`, `stream`
- ✅ Public dashboards work without modification
- ✅ Can filter by namespace using dashboard variables
- ✅ Can filter by container using dashboard variables
- ✅ Can distinguish stdout vs stderr logs
- ✅ No Fluent Bit crashes or errors
- ✅ No high-cardinality warnings from Loki