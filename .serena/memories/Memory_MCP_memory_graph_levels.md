# Memory Graph Levels

**Purpose:** The project graph is a single connected structure anchored at `IDP-Blueprint`. Always start traversals there.

## Level 0 — Root
- Only node: `IDP-Blueprint` (project abstract entry point).
- Outgoing edges: `VIEW` relations to Level‑1 nodes.
- Incoming edges: none.
- Observations describe the project (type, goal, tooling, collaboration) but never implementation details.

## Level 1 — Perspectives
- Nodes: `Architecture View`, `Workloads View`, `Operations View`, `Documentation View`, `Security View`, `Observability View`, `Eventing View` (extend only when a new viewpoint is truly needed).
- Incoming: exactly one `VIEW` edge from `IDP-Blueprint`.
- Outgoing: edges to Level‑2 nodes using single-word relation verbs (`COVERS`, `INCLUDES`, `USES`, `DOCS`, `SECURES`, `MONITORS`, `TRIGGERS`, etc.).
- No edges between perspectives.

## Level 2 — Stacks, Components, Docs, Concepts
- Contains every other entity (layers, stacks, deployables, Kubernetes resources, DocPages, etc.).
- Can have arbitrary edges to other Level‑2 nodes (documented_by, depends_on, uses, etc.).
- May have edges from multiple perspectives (for example, `Vault` is `INCLUDES` from Workloads View and `SECURES` from Security View).

## Rules for Modifications
1. Keep the “three-tier” structure: Root→View→Details. Never connect a detail node directly back to the root or to another view.
2. Relation names should be single words describing the action (e.g., `COVERS`, `INCLUDES`). Reuse existing verbs when possible.
3. When adding new Level‑2 nodes, link them through the relevant view(s) so they remain reachable from `IDP-Blueprint`.
4. Remove or merge nodes that only duplicate navigation, audits, or implementation minutiae—those belong in the code/docs, not the graph.
5. After edits, ensure there is still a single connected component by starting at `IDP-Blueprint` and checking reachability.

Following this model keeps the graph concise, orderly, and useful for LLM agents exploring architecture, workloads, operations, or documentation from their preferred perspective.