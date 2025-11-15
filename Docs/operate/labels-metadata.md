---
# Labels & Metadata — Contracts you can select on

Labels are contracts. They enable selection, grouping, and FinOps. Use annotations for human/URL metadata.

## Canonical set

- `app.kubernetes.io/{name,instance,version,component,part-of}`
- `owner`, `business-unit`, `environment`

Enforce presence with Kyverno; validate with `Scripts/validate-consistency.sh`.

See also: reference/labels-standard.md and guides/policy-tagging.md.

