---
title: Operate — run the platform in practice
---
---

This section focuses on day‑2 operation: backups, upgrades, scaling, and recovery. It
assumes you have deployed the platform and understand the basics of its architecture.

There is no new mental model here; we reuse the same Desired/Observed/Actionable loops
from [Concepts](../concepts/index.md). The emphasis is on concrete runbooks.

## What “good operations” means for this IDP

- SLOs as code (Pyrra) define expectations; burn rates lead to actions.
- GitOps and policies keep intent and reality aligned; drift is corrected automatically.
- Runbooks capture steps for common failure modes and routine tasks.
- Backups focus on state that cannot be recreated deterministically from Git.

## Runbooks you will rely on

Start with these documents when operating the platform:

- [Backup & restore](../operate/backup-restore.md) — what to back up vs what to rebuild.
- [Upgrades](../operate/upgrades.md) — order, gates, and rollback strategies.
- [Scaling & tuning](../operate/scaling-tuning.md) — key knobs (retention, cardinality, priorities).
- [Disaster recovery](../operate/disaster-recovery.md) — rebuild from Git and restore secrets.
