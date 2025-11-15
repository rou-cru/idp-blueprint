---
# Feature Toggles & Profiles — Knobs, switches, and fuses

This IDP exposes stack‑level toggles (“fuses”) so you can shape a deployment before syncing anything. Start simple with stack switches, then evolve toward finer‑grained controls per component.

## Stack fuses (today)

Defined in `config.toml` under `[fuses]`:

```toml
[fuses]
policies = true        # Kyverno + Policies app
security = true        # Security stack (Trivy Operator)
observability = true   # Prometheus + Grafana + Loki + Fluent-bit (+ Pyrra)
cicd = true            # Argo Workflows + templates
prod = false           # Hardened profile (HA switches)
```

Runtime behavior:
- `task stacks:deploy` reads fuses and applies only the enabled stacks.
- `fuses.prod = true` enables production hardening (today: HA for ArgoCD; future: more dials).

```d2
direction: right

Fuses: {
  Policies: "on/off"
  Security: "on/off"
  Observ: "on/off"
  CICD: "on/off"
  Prod: "profile"
}

Deploy: {
  Policies: "Kyverno"
  Security: "Trivy"
  Observ: "KPS + Loki + FB + Pyrra"
  CICD: "Argo Workflows"
}

Fuses.Policies -> Deploy.Policies
Fuses.Security -> Deploy.Security
Fuses.Observ -> Deploy.Observ
Fuses.CICD -> Deploy.CICD
Fuses.Prod -> Deploy: "HA / hardening flags"
```

Try it:

```bash
# Show effective values
task config:print

# Example: disable security stack, enable everything else
uv run dasel put -r toml -f config.toml fuses.security false >/dev/null
task deploy
```

## Profiles (concept → practice)

Three reference profiles to guide safe defaults:

- Demo (current defaults)
  - Fuses: all stacks on
  - Kyverno: audit (no enforce)
  - HA: off; minimal persistence
  - Retentions: short (Prometheus 6h)

- Staging (candidate; not wired yet)
  - Fuses: all stacks on
  - Kyverno: audit (plus extra checks)
  - HA: selective (ArgoCD on, others optional)
  - Retentions: medium; basic alerting receivers

- Prod (partial today via `fuses.prod=true`)
  - Fuses: on per need
  - Kyverno: audit (today); plan to move critical to enforce
  - HA: enable for control planes (ArgoCD done; extend to ESO/cert-manager as needed)
  - Retentions/persistence: real PVCs; longer retention; tuned resources

Suggested TOML extension (future):

```toml
[profiles]
active = "demo" # or staging/prod

[profiles.staging]
observability.retention = "24h"
argocd.ha = true
alerts.enabled = true
```

## Kyverno mode

By design (for now), policies use `validationFailureAction: audit`. This keeps the road paved without blocking deploys. Candidates to enforce later:
- Namespace labels (already enforced)
- Component labels on Deployments/StatefulSets
- PriorityClass required for workloads
- ESO `creationPolicy: Merge` for sensitive targets

## Fine‑grained toggles (future)

Useful switches inside big stacks:
- Observability: `alertmanager.enabled`, `loki.enabled`, `fluent-bit.enabled`, `pyrra.enabled`
- Security: `trivy.enabled`, `image-policy.enabled`
- Delivery: `rollouts.enabled`, `kargo.enabled`

Implementation options:
- Pass `--set enabled=<bool>` when charts support it (Tasks detect fuses and add flags).
- Split subcomponents into separate Application folders and gate per‑folder.

## Reference

- Effective config: `task config:print`
- Contracts & Guardrails: [operate/contracts.md](contracts.md)

